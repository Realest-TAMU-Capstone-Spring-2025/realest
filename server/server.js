const express = require('express');
const axios = require('axios');
const app = express();
const path = require('path');
require('dotenv').config();
const port = 3000;

// Middleware to parse JSON requests
app.use(express.json());

// Serve static files from the 'images' folder (if you have local images)
app.use('/images', express.static(path.join(__dirname, 'images')));

// CORS configuration to allow requests from any origin
app.use((req, res, next) => {
    res.header('Access-Control-Allow-Origin', '*'); // Allow all origins for development
    res.header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    res.header('Access-Control-Allow-Headers', 'Content-Type');
    if (req.method === 'OPTIONS') {
        return res.sendStatus(200); // Handle preflight requests
    }
    next();
});

// Proxy endpoint to fetch remote images
app.get('/proxy-image', async (req, res) => {
    const { url } = req.query; // e.g., ?url=http://ap.rdcpix.com/...
    if (!url) {
        return res.status(400).send('URL parameter is required');
    }
    try {
        const response = await axios.get(url, { responseType: 'stream' });
        res.set('Content-Type', response.headers['content-type']);
        response.data.pipe(res); // Stream the image back to the client
    } catch (error) {
        console.error('Error proxying image:', error.message);
        res.status(500).send('Failed to fetch image');
    }
});

// SendGrid API details
const SENDGRID_API_KEY = process.env.SENDGRID_API_KEY;
const SENDER_EMAIL = 'eshwarreddygadi@gmail.com';

// Endpoint to send an email
app.post('/send-email', async (req, res) => {
    const { clientEmail, invitationCode } = req.body;

    // Validate input
    if (!clientEmail || !invitationCode) {
        return res.status(400).json({ error: 'clientEmail and invitationCode are required' });
    }

    const emailData = {
        personalizations: [
            {
                to: [{ email: clientEmail }],
            },
        ],
        from: { email: SENDER_EMAIL, name: 'RealEst App' },
        subject: 'Invitation to Join Realtor App',
        content: [
            {
                type: 'text/plain',
                value: `
Dear Client,

You have been invited to join the Realtor App! Please follow these steps to get started:

1. Download and install the Realtor App from the Google Play Store or Apple App Store.
2. Create an account using your email address.
3. Enter the following invitation code to log in and access all features:

Invitation Code: ${invitationCode}

We look forward to having you on board!

Best regards,
The Realtor App Team
                `,
            },
        ],
    };

    try {
        const response = await axios.post(
            'https://api.sendgrid.com/v3/mail/send',
            emailData,
            {
                headers: {
                    'Authorization': `Bearer ${SENDGRID_API_KEY}`,
                    'Content-Type': 'application/json',
                },
            }
        );

        // SendGrid returns 202 on success
        if (response.status === 202) {
            res.status(202).json({ message: 'Email sent successfully' });
        } else {
            res.status(response.status).json({ error: 'Failed to send email' });
        }
    } catch (error) {
        console.error('Error sending email:', error.response?.data || error.message);
        res.status(500).json({ error: 'Internal server error' });
    }
});

// Start the server
app.listen(port, '0.0.0.0', () => {
    console.log(`Server running on http://localhost:${port}`);
});