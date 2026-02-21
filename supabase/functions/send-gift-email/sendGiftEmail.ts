// Import the Resend client for Deno
import { Resend } from "https://esm.sh/resend@2.0.0";

// Email Components
// ----------------

// Header Component
function createHeaderComponent(): string {
  return `
    <div class="header">
      <h1>Du har mottatt en Hilsen! 🎁</h1>
    </div>
  `;
}

// Main Content Component
function createContentComponent(params: {
  cardFrontsideUrl: string;
  openGiftUrl: string;
}): string {
  return `
    <div class="content">
      <p style="font-size: 16px; line-height: 1.5;">Noen har sendt deg en personlig Hilsen. Åpne den for å se hva de har skrevet til deg.</p>
      
      <img src="${params.cardFrontsideUrl}" alt="Card Image" class="card-image">
      
      <p style="font-size: 16px; margin-top: 20px;">Klikk på knappen under for å åpne hilsenen din:</p>
      <div style="text-align: center;">
        <a href="${params.openGiftUrl}" class="button">Åpne i nettleser</a>
      </div>
      
      <p style="font-size: 14px; color: #666; margin-top: 15px;">Eller kopier denne lenken inn i nettleseren din:</p>
      <p style="font-size: 14px; color: #5b3cc4; word-break: break-all;">${params.openGiftUrl}</p>
    </div>
  `;
}

// App Promotion Component
function createAppPromotionComponent(): string {
  return `
    <div class="app-promotion">
      <div class="promotion-text">
        <p class="promotion-title">Prøv selv</p>
        <p class="promotion-description">Send en Hilsen til noen du er glad i i dag!</p>
      </div>
      
      <div class="app-buttons">
        <table align="center" border="0" cellpadding="0" cellspacing="0" role="presentation">
          <tr>
            <td style="padding-right: 16px;">
              <a href="https://play.google.com/store/apps/details?id=app.hilsen.hilsen" target="_blank">
                <img 
                  alt="Get it on Google Play button" 
                  height="54" 
                  src="https://react.email/static/get-it-on-google-play.png" 
                  style="border: none; display: block;" 
                />
              </a>
            </td>
            <td style="padding-left: 16px;">
              <a href="https://apps.apple.com/us/app/hilsen/id6739460078" target="_blank">
                <img 
                  alt="Download on the App Store button" 
                  height="54" 
                  src="https://react.email/static/download-on-the-app-store.png" 
                  style="border: none; display: block;" 
                />
              </a>
            </td>
          </tr>
        </table>
      </div>
    </div>
  `;
}

// Footer Component
function createFooterComponent(): string {
  return `
    <div class="footer">
      <p>© 2025 Hilsen App. Alle rettigheter reservert.</p>
    </div>
  `;
}

// CSS Styles Component
function createStylesComponent(): string {
  return `
    <style>
      body {
        font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif;
        margin: 0;
        padding: 0;
        color: #333333;
        background-color: #f5f5f5;
      }
      .container {
        max-width: 600px;
        margin: 0 auto;
        padding: 20px;
      }
      .header {
        background-color: #5b3cc4;
        padding: 25px;
        text-align: center;
        border-radius: 12px 12px 0 0;
        color: white;
        box-shadow: 0 2px 4px rgba(0,0,0,0.1);
      }
      .header h1 {
        margin: 0;
        font-size: 28px;
        letter-spacing: 0.5px;
      }
      .content {
        background-color: #ffffff;
        padding: 30px;
        border-radius: 0 0 12px 12px;
        border: 1px solid #e0e0e0;
        box-shadow: 0 2px 4px rgba(0,0,0,0.05);
      }
      .card-image {
        width: 100%;
        max-width: 100%;
        margin: 25px 0;
        border-radius: 12px;
        box-shadow: 0 4px 8px rgba(0,0,0,0.1);
      }
      .button {
        display: block;
        width: calc(100% - 48px);
        background-color: #5b3cc4;
        color: white;
        text-decoration: none;
        padding: 16px 24px;
        border-radius: 24px;
        margin: 25px auto;
        font-weight: bold;
        font-size: 18px;
        text-align: center;
        transition: background-color 0.3s;
        box-shadow: 0 2px 4px rgba(91,60,196,0.3);
        max-width: 450px;
      }
      .button:hover {
        background-color: #4a30a0;
      }
      .app-promotion {
        margin-top: 35px;
        padding: 25px;
        background-color: #f9f5ff;
        border: 1px solid #e0d5ff;
        border-radius: 12px;
        text-align: center;
      }
      .promotion-title {
        color: #5b3cc4;
        font-weight: 700;
        font-size: 22px;
        line-height: 28px;
        margin-bottom: 5px;
      }
      .promotion-description {
        color: #333333;
        margin-bottom: 25px;
        font-size: 16px;
      }
      .app-buttons {
        margin: 20px 0;
      }
      .footer {
        margin-top: 25px;
        text-align: center;
        color: #777777;
        font-size: 13px;
      }
    </style>
  `;
}

// Main Email Template Assembly
function createEmailTemplate(params: {
  cardFrontsideUrl: string;
  openGiftUrl: string;
}): string {
  // Assemble components
  const headerSection = createHeaderComponent();
  const mainContentSection = createContentComponent(params);
  const appPromotionSection = createAppPromotionComponent();
  const footerSection = createFooterComponent();
  const stylesSection = createStylesComponent();

  // Combine everything into a complete HTML email
  return `
    <!DOCTYPE html>
    <html>
      <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <title>You've received a gift!</title>
        ${stylesSection}
      </head>
      <body>
        <div class="container">
          ${headerSection}
          ${mainContentSection}
          ${appPromotionSection}
          ${footerSection}
        </div>
      </body>
    </html>
  `;
}

// Email sending function for the Supabase Edge Function
export async function sendGiftEmail(params: {
  senderFirstName: string;
  recipientEmail: string;
  greetingCardId: string;
  cardFrontsideUrl: string;
}): Promise<boolean> {
  try {
    // Get the Resend API key from environment variable
    const resendApiKey = Deno.env.get("RESEND_API_KEY");
    const baseUrl = Deno.env.get("BASE_URL");

    if (!resendApiKey) {
      console.error("Missing RESEND_API_KEY environment variable");
      throw new Error("Missing RESEND_API_KEY environment variable");
    }

    if (!baseUrl) {
      console.error("Missing BASE_URL environment variable");
      throw new Error("Missing BASE_URL environment variable");
    }

    // Initialize Resend client
    const resend = new Resend(resendApiKey);

    // Create HTML email content
    const htmlContent = createEmailTemplate({
      openGiftUrl: `${baseUrl}/open/${params.greetingCardId}`,
      cardFrontsideUrl: params.cardFrontsideUrl,
    });

    console.log("Recipient email:", params.recipientEmail);

    // Send email
    const { data, error } = await resend.emails.send({
      from: `${params.senderFirstName} <hei@hilsen.app>`,
      to: [params.recipientEmail],
      subject: `${params.senderFirstName} har sendt deg en hilsen!`,
      html: htmlContent,
    });

    console.log("Resend email data:", data);

    if (error) {
      console.error("Resend email error:", error);
      throw new Error(`Failed to send email: ${error.message}`);
    }

    return true;
  } catch (error) {
    console.error("Error sending email:", error);
    throw error;
  }
}
