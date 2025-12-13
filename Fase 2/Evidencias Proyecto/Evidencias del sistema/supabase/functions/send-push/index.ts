// Supabase Edge Function: envía un push usando FCM HTTP v1.
// Espera body JSON: { token, title, body, data? }
// Requiere el secreto FCM_SERVICE_ACCOUNT con el JSON de cuenta de servicio.

import { GoogleAuth } from "npm:google-auth-library";

const PROJECT_ID = "agendio-bf0af";

const raw = Deno.env.get("FCM_SERVICE_ACCOUNT");
if (!raw) {
  throw new Error("FCM_SERVICE_ACCOUNT not set");
}
const serviceAccount = JSON.parse(raw);

export default async (req: Request): Promise<Response> => {
  try {
    const { token, title, body, data } = await req.json();

    if (!token) {
      return new Response("Missing token", { status: 400 });
    }

    const auth = new GoogleAuth({
      credentials: serviceAccount,
      scopes: ["https://www.googleapis.com/auth/firebase.messaging"],
    });
    const accessToken = await auth.getAccessToken();

    const res = await fetch(
      `https://fcm.googleapis.com/v1/projects/${PROJECT_ID}/messages:send`,
      {
        method: "POST",
        headers: {
          Authorization: `Bearer ${accessToken}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          message: {
            token,
            notification: title || body ? { title, body } : undefined,
            data: data ?? {},
          },
        }),
      },
    );

    if (!res.ok) {
      const err = await res.text();
      return new Response(err, { status: 500 });
    }

    const out = await res.json();
    return new Response(JSON.stringify(out), { status: 200 });
  } catch (e) {
    return new Response(String(e), { status: 500 });
  }
};
