// case-refs-mutate — Edge Function pra mutations do banco de referências
// POST body:
//   { op: 'update_note', id: number, notas: string }
//   { op: 'update_tags', id: number, tags: string[] }
//   { op: 'soft_delete', id: number }
//   { op: 'promote_editorial', id: number,
//     quando_usar: string, por_que_funciona: string,
//     como_adaptar: string, objetivo?: string }         -- E02: 3 campos obrigatorios
//   { op: 'unpromote', id: number }                     -- volta pro /live
// Delega pra RPC functions no schema public (SECURITY DEFINER) que escrevem em agente.
//
// op 'promote' (legacy) foi removido — a check constraint
// chk_promoted_requires_editorial_fields impede promover sem os 3 campos.

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization, apikey, x-client-info",
};

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

async function callRpc(fn: string, args: Record<string, unknown>): Promise<{ ok: boolean; data?: unknown; error?: string }> {
  const res = await fetch(`${SUPABASE_URL}/rest/v1/rpc/${fn}`, {
    method: "POST",
    headers: {
      apikey: SERVICE_ROLE_KEY,
      Authorization: `Bearer ${SERVICE_ROLE_KEY}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify(args),
  });
  let data: any = null;
  try { data = await res.json(); } catch {}
  if (!res.ok) return { ok: false, error: data?.message || `HTTP ${res.status}` };
  return { ok: true, data };
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response(null, { headers: corsHeaders });
  if (req.method !== "POST") return jsonResponse({ ok: false, error: "method_not_allowed" }, 405);

  let body: any;
  try { body = await req.json(); } catch {
    return jsonResponse({ ok: false, error: "invalid_json" }, 400);
  }

  const op = body.op;
  // id pode chegar como string (bigint do Postgres vira string no n8n)
  const id = Number(body.id);
  if (!op || !Number.isFinite(id)) {
    return jsonResponse({ ok: false, error: "missing_op_or_id" }, 400);
  }

  if (op === "update_note") {
    const notas = typeof body.notas === "string" ? body.notas : "";
    const r = await callRpc("case_refs_update_note", { p_id: id, p_notas: notas });
    if (!r.ok) return jsonResponse({ ok: false, error: r.error }, 500);
    return jsonResponse({ ok: true, op, data: r.data });
  }

  if (op === "update_tags") {
    const tags = Array.isArray(body.tags) ? body.tags.map((t: any) => String(t)) : [];
    const r = await callRpc("case_refs_update_tags", { p_id: id, p_tags: tags });
    if (!r.ok) return jsonResponse({ ok: false, error: r.error }, 500);
    return jsonResponse({ ok: true, op, data: r.data });
  }

  if (op === "soft_delete") {
    const r = await callRpc("case_refs_soft_delete", { p_id: id });
    if (!r.ok) return jsonResponse({ ok: false, error: r.error }, 500);
    return jsonResponse({ ok: true, op, data: r.data });
  }

  if (op === "promote_editorial") {
    const quando_usar      = typeof body.quando_usar === "string" ? body.quando_usar.trim() : "";
    const por_que_funciona = typeof body.por_que_funciona === "string" ? body.por_que_funciona.trim() : "";
    const como_adaptar     = typeof body.como_adaptar === "string" ? body.como_adaptar.trim() : "";
    const objetivo         = typeof body.objetivo === "string" ? body.objetivo.trim() : "";

    const missing: string[] = [];
    if (quando_usar.length < 20)      missing.push("quando_usar");
    if (por_que_funciona.length < 20) missing.push("por_que_funciona");
    if (como_adaptar.length < 20)     missing.push("como_adaptar");

    if (missing.length > 0) {
      return jsonResponse(
        { ok: false, error: "missing_editorial_fields", fields: missing },
        422,
      );
    }

    const r = await callRpc("case_refs_promote_editorial", {
      p_id: id,
      p_quando_usar: quando_usar,
      p_por_que_funciona: por_que_funciona,
      p_como_adaptar: como_adaptar,
      p_objetivo: objetivo || null,
    });
    if (!r.ok) {
      // Postgres RAISE EXCEPTION com missing_editorial_fields => devolve 422
      const isFieldsErr = typeof r.error === "string" && r.error.includes("missing_editorial_fields");
      return jsonResponse({ ok: false, error: r.error }, isFieldsErr ? 422 : 500);
    }
    return jsonResponse({ ok: true, op, data: r.data });
  }

  if (op === "unpromote") {
    const r = await callRpc("case_refs_unpromote", { p_id: id });
    if (!r.ok) return jsonResponse({ ok: false, error: r.error }, 500);
    return jsonResponse({ ok: true, op, data: r.data });
  }

  // store_thumb — baixa a imagem (CDN do IG expira em horas/dias) e persiste
  // no bucket público refs-thumbs; grava thumb_storage_url na linha.
  // Server-side: sem CORS e sem service key fora daqui. Chamado pelo n8n no
  // ingest e pelo workflow de reprocessamento/backfill.
  //   { op: 'store_thumb', id: number, url?: string }
  // Sem `url`, usa cover_url/display_url da própria linha.
  if (op === "store_thumb") {
    let srcUrl = typeof body.url === "string" && body.url.startsWith("http") ? body.url : null;
    if (!srcUrl) {
      const row = await fetch(
        `${SUPABASE_URL}/rest/v1/v_referencias_publicas?select=thumb_url&id=eq.${id}`,
        { headers: { apikey: SERVICE_ROLE_KEY, Authorization: `Bearer ${SERVICE_ROLE_KEY}` } },
      ).then((r) => r.json()).catch(() => null);
      srcUrl = row?.[0]?.thumb_url || null;
    }
    if (!srcUrl) return jsonResponse({ ok: false, error: "no_source_url" }, 422);

    let img: Response;
    try {
      img = await fetch(srcUrl, { headers: { "User-Agent": "Mozilla/5.0" } });
    } catch (e) {
      return jsonResponse({ ok: false, error: `download_failed: ${e}` }, 502);
    }
    if (!img.ok) return jsonResponse({ ok: false, error: `download_http_${img.status}` }, 502);
    const contentType = img.headers.get("content-type") || "image/jpeg";
    if (!contentType.startsWith("image/")) {
      return jsonResponse({ ok: false, error: `not_an_image: ${contentType}` }, 422);
    }
    const bytes = new Uint8Array(await img.arrayBuffer());
    if (bytes.length === 0) return jsonResponse({ ok: false, error: "empty_image" }, 422);
    if (bytes.length > 5 * 1024 * 1024) return jsonResponse({ ok: false, error: "image_too_large" }, 422);

    const ext = contentType.includes("png") ? "png" : contentType.includes("webp") ? "webp" : "jpg";
    const path = `ref-${id}.${ext}`;
    const up = await fetch(`${SUPABASE_URL}/storage/v1/object/refs-thumbs/${path}`, {
      method: "POST",
      headers: {
        apikey: SERVICE_ROLE_KEY,
        Authorization: `Bearer ${SERVICE_ROLE_KEY}`,
        "Content-Type": contentType,
        "x-upsert": "true",
      },
      body: bytes,
    });
    if (!up.ok) {
      const err = await up.text().catch(() => "");
      return jsonResponse({ ok: false, error: `upload_failed: ${up.status} ${err.slice(0, 200)}` }, 502);
    }

    const publicUrl = `${SUPABASE_URL}/storage/v1/object/public/refs-thumbs/${path}`;
    const upd = await fetch(`${SUPABASE_URL}/rest/v1/rpc/case_refs_set_thumb_storage`, {
      method: "POST",
      headers: {
        apikey: SERVICE_ROLE_KEY,
        Authorization: `Bearer ${SERVICE_ROLE_KEY}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ p_id: id, p_url: publicUrl }),
    });
    if (!upd.ok) {
      const err = await upd.text().catch(() => "");
      return jsonResponse({ ok: false, error: `row_update_failed: ${err.slice(0, 200)}` }, 500);
    }
    return jsonResponse({ ok: true, op, thumb_storage_url: publicUrl, bytes: bytes.length });
  }

  return jsonResponse({ ok: false, error: "unknown_op", op }, 400);
});
