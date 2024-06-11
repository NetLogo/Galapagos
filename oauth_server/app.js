/*
Server for getting credentials and then generating accessToken to upload to GitHub

Alison Bai Netlogo

Resource: https://docs.github.com/en/apps/oauth-apps/building-oauth-apps/creating-an-oauth-app

Note: if there's any packages that are not within node, if anything else needed to be installed
then it needs a package.json
*/


require('dotenv').config();
const express = require('express');
const axios = require('axios');

const app = express();
const port = process.env.PORT || 3000;

//Test to see if the server is responsive
app.get('/', (req, res) => {
  res.send('Hello World!');
});


app.listen(port, () => {
  console.log(`Server listening at http://localhost:${port}`);
});

//Call the Github Auth Application and send to the Redirect URI
app.get('/auth/github', (req, res) => {
    console.log('auth_github passsed')
    const clientId = process.env.GITHUB_CLIENT_ID; //configure in .env with GitHub
    const redirectUri = 'http://localhost:3000/auth/github/callback';
    const scope = 'gist repo'; // Adjust the scope according to your needs
    res.redirect(`https://github.com/login/oauth/authorize?client_id=${clientId}&redirect_uri=${encodeURIComponent(redirectUri)}&scope=${encodeURIComponent(scope)}`);
  });


//Call and watifor response from GitHub OAuth, store in a cookie to send back to client
app.get('/auth/github/callback', async (req, res) => {
    console.log("callback")
    const code = req.query.code;
    const clientId = process.env.GITHUB_CLIENT_ID;
    const clientSecret = process.env.GITHUB_CLIENT_SECRET;

    try {
        const response = await axios.post('https://github.com/login/oauth/access_token', {
            client_id: clientId,
            client_secret: clientSecret,
            code: code,
        }, {
            headers: {
                'Accept': 'application/json'
            }
        });

        const accessToken = response.data.access_token;
        console.log(accessToken)
        // Store the access token in an HTTP-only cookie
        res.cookie('accessToken', accessToken, { secure: true, sameSite: 'strict' });
        // Redirect to a page that will send a postMessage to the client
        res.redirect('/auth/success'); // Create this endpoint or page
    } catch (error) {
        res.status(500).send('Authentication failed');
    }
});


// Endpoint for the successful authentication page
app.get('/auth/success', (req, res) => {
    const html = `
        <html>
            <body>
                <script>
                    // Send a message to the opener window with the success event
                    window.opener.postMessage({
                        type: 'authentication_complete'
                    }, 'http://localhost:9000'); // Ensure this is the correct client origin
                    window.close(); // Close the popup
                </script>
                <p>Authentication successful! You may close this window.</p>
            </body>
        </html>
    `;
    res.send(html);
});

app.get('/api/use_access_token', (req, res) => {
    const accessToken = req.cookies['accessToken'];
    if (!accessToken) {
        return res.status(401).json({ error: 'Access token is missing' });
    }
    // Use the accessToken to interact with the GitHub API here
});

app.get('/api/proceed_with_auth', async (req, res) => {
    const accessToken = req.cookies['accessToken'];
    if (!accessToken) {
        return res.status(401).json({ error: 'Access token is missing' });
    }

    try {
        // Here, you'd use the accessToken as needed for your application logic
        // For example, interacting with the GitHub API
        console.log("Access token:", accessToken);
        // You can perform operations with the GitHub API or any other actions required

        res.json({ success: true, message: "Proceeding with authenticated actions" });
    } catch (error) {
        console.error("Error in proceeding with auth:", error);
        res.status(500).json({ error: 'Failed to proceed with authentication' });
    }
});


//Calling upload nlogo file through the server attempt
app.post('/api/upload-nlogo', async (req, res) => {
    const { filename, content } = req.body;
    const accessToken = req.cookies['accessToken']; // Assuming the access token is stored in an HttpOnly cookie
  
    if (!accessToken) {
      return res.status(401).json({ error: 'Access token is missing or invalid' });
    }
  
    const data = {
      "description": "Uploaded from NetLogo",
      "public": true,
      "files": {
        [filename]: { "content": content }
      }
    };
  
    try {
      const response = await axios.post('https://api.github.com/gists', data, {
        headers: {
          'Authorization': `token ${accessToken}`,
          'Content-Type': 'application/json'
        }
      });
  
      if (response.status === 201) { // HTTP 201 Created
        const gistUrl = response.data.html_url;
        console.log("Gist created:", gistUrl);
        res.json({ message: "Successfully uploaded to GitHub Gist", gistUrl: gistUrl });
      } else {
        console.error("Failed to create Gist:", response.status);
        res.status(500).json({ error: 'Failed to upload to GitHub Gist' });
      }
    } catch (error) {
      console.error("Error interacting with GitHub API:", error);
      res.status(500).json({ error: 'Error uploading to GitHub Gist' });
    }
  });

