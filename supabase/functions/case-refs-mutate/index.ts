// case-refs-mutate — Edge Function pra mutations do banco de referências
// POST body:
//   { op: 'update_note', id: number, notas: string }
//   { op: 'update_tags', id: number, tags: string[] }
//   { op: 'soft_delete', id: number }
// Delega pra RPC functions no schema public (SECURITY DEFINER) que escrevem em agente.

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

  const { op, id } = body;
  if (!op || typeof id !== "number") {
    return jsonResponse({ ok: false, error: "missing_op_or_id" }, 400);
  }

  if (op === "update_note") {
    const notas = typeof body.notas === "string" ? body.notas : "";
    const r = await callRpc("case_refs_update_note", { p_id: id, p_notas: notas });
    if (!r.ok) return jsonResponse({ ok: false, error: r.error }, 500);
    return jsonResponse({ ok: true, op, ...r.data });
  }

  if (op === "update_tags") {
    const tags = Array.isArray(body.tags) ? body.tags.map((t: any) => String(t)) : [];
    const r = await callRpc("case_refs_update_tags", { p_id: id, p_tags: tags });
    if (!r.ok) return jsonResponse({ ok: false, error: r.error }, 500);
    return jsonResponse({ ok: true, op, ...r.data });
  }

  if (op === "soft_delete") {
    const r = await callRpc("case_refs_soft_delete", { p_id: id });
    if (!r.ok) return jsonResponse({ ok: false, error: r.error }, 500);
    return jsonResponse({ ok: true, op, ...r.data });
  }

  return jsonResponse({ ok: false, error: "unknown_op", op }, 400);
});
