// lib/core/templates/email_templates.dart

class EmailTemplates {
  /// Returns the premium HTML template for the Welcome Email
  static String welcomeEmail(String name) {
    return '''
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Welcome to Laween</title>
    <style>
        @import url('https://fonts.googleapis.com/css2?family=Outfit:wght@400;600;900&family=Inter:wght@400;600&display=swap');
        
        body {
            margin: 0;
            padding: 0;
            background-color: #1F1F1F;
            font-family: 'Inter', Arial, sans-serif;
            -webkit-font-smoothing: antialiased;
            color: #ffffff;
        }
        
        .wrapper {
            width: 100%;
            table-layout: fixed;
            background-color: #1F1F1F;
            padding-bottom: 60px;
        }
        
        .main-table {
            background-color: #2C2C2C;
            margin: 40px auto;
            width: 100%;
            max-width: 600px;
            border-radius: 24px;
            overflow: hidden;
            box-shadow: 0 20px 40px rgba(0, 0, 0, 0.5);
            border: 1px solid #3d3d3d;
        }

        .header {
            background: linear-gradient(135deg, #006D77 0%, #00C9A7 100%);
            padding: 40px 20px;
            text-align: center;
        }

        .header h1 {
            font-family: 'Outfit', Arial, sans-serif;
            color: #ffffff;
            font-size: 32px;
            font-weight: 900;
            margin: 0;
            letter-spacing: 2px;
            text-shadow: 0 4px 10px rgba(0,0,0,0.2);
        }
        
        .content {
            padding: 40px 30px;
            background-color: #2C2C2C;
            text-align: center;
        }

        .content h2 {
            font-family: 'Outfit', Arial, sans-serif;
            color: #ffffff;
            font-size: 24px;
            font-weight: 600;
            margin-top: 0;
            margin-bottom: 20px;
        }

        .content p {
            color: #94A3B8;
            font-size: 16px;
            line-height: 1.6;
            margin-bottom: 30px;
        }
        
        .feature-box {
            background-color: #1F1F1F;
            border-radius: 16px;
            padding: 24px;
            margin-bottom: 30px;
            border: 1px solid #3d3d3d;
        }

        .feature-box h3 {
            color: #D4AF37;
            font-family: 'Outfit', Arial, sans-serif;
            font-size: 18px;
            margin-top: 0;
            margin-bottom: 10px;
        }

        .feature-box p {
            font-size: 14px;
            margin-bottom: 0;
        }

        .btn {
            display: inline-block;
            background-color: #006D77;
            color: #ffffff !important;
            text-decoration: none;
            padding: 16px 36px;
            border-radius: 12px;
            font-family: 'Outfit', Arial, sans-serif;
            font-weight: 600;
            font-size: 16px;
            text-transform: uppercase;
            letter-spacing: 1px;
            box-shadow: 0 8px 20px rgba(0, 109, 119, 0.4);
            transition: all 0.3s ease;
        }

        .footer {
            background-color: #1a1a1a;
            padding: 30px;
            text-align: center;
        }

        .footer p {
            color: #666666;
            font-size: 12px;
            margin: 0;
            line-height: 1.5;
        }

        .footer a {
            color: #00C9A7;
            text-decoration: none;
        }
    </style>
</head>
<body>
    <center class="wrapper">
        <table class="main-table" width="100%" cellspacing="0" cellpadding="0">
            <tr>
                <td class="header">
                    <h1>LAWEEN</h1>
                </td>
            </tr>
            <tr>
                <td class="content">
                    <h2>Welcome to the Vibe, ${name.split(' ')[0]}! 🕊️</h2>
                    <p>
                        You're officially off the waitlist and into the ultimate social coordination ecosystem. Say goodbye to the endless "where should we go?" texts.
                    </p>
                    
                    <div class="feature-box">
                        <h3>Discover. Vote. Arrive.</h3>
                        <p>
                            Create an Outing, invite your friends, let Laween calculate the best midpoint venues, and vote together in real-time. It's that simple.
                        </p>
                    </div>

                    <a href="laween://app" class="btn">Start an Outing</a>
                </td>
            </tr>
            <tr>
                <td class="footer">
                    <p>
                        © 2026 Laween App. All rights reserved.<br>
                        Designed with 💎 for a premium coordination experience.<br>
                        <a href="https://laween.com/privacy">Privacy Policy</a> | <a href="https://laween.com/terms">Terms of Service</a>
                    </p>
                </td>
            </tr>
        </table>
    </center>
</body>
</html>
''';
  }
}
