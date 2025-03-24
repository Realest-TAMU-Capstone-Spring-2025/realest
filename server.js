const cors_proxy = require('cors-anywhere');

const host = '0.0.0.0';
const port = 8080;

cors_proxy.createServer({
   originWhitelist: [], // Allow all origins
   requireHeader: [], // Disable required headers
   removeHeaders: ['cookie', 'cookie2']
}).listen(port, host, function() {
   console.log('CORS Proxy running on http://' + host + ':' + port);
});
