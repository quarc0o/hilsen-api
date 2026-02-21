// Follow this setup guide to integrate the Deno language server with your editor:
// https://deno.land/manual/getting_started/setup_your_environment
// This enables autocomplete, go to definition, etc.

// Setup type definitions for built-in Supabase Runtime APIs
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { sendGiftEmail } from "./sendGiftEmail.ts";

// CORS headers for web support
const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

Deno.serve(async (req: Request) => {
  // Handle CORS preflight requests
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // const supabaseClient = createSupabaseClient();
    const {
      recipient_mail,
      sender_name,
      greeting_card_id,
      card_frontside_url,
    } = await req.json();

    await sendGiftEmail({
      senderFirstName: sender_name,
      recipientEmail: recipient_mail,
      greetingCardId: greeting_card_id,
      cardFrontsideUrl: card_frontside_url,
    });

    return new Response(JSON.stringify({ success: true }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 200,
    });
  } catch (e) {
    console.log("Error sending gift: ", e);

    return new Response(
      JSON.stringify({
        error: "Failed to send gift email",
        details: e.message,
      }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 500,
      }
    );
  }
});
