import http from 'k6/http';
import { check } from 'k6';

export let options = {
  insecureSkipTLSVerify: true,
  vus: 1,
};

export default function () {
  var url = `https://${__ENV.SERVER_IP}:31001/api/v1/namespaces/guest/actions/${__ENV.FUNCTION}?blocking=true&result=true`;

  var payload = `${__ENV.PAYLOAD}`;

  // console.log(payload);

  var params = {
    timeout: 90000,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Basic MjNiYzQ2YjEtNzFmNi00ZWQ1LThjNTQtODE2YWE0ZjhjNTAyOjEyM3pPM3haQ0xyTU42djJCS0sxZFhZRnBYbFBrY2NPRnFtMTJDZEFzTWdSVTRWck5aOWx5R1ZDR3VNREdJd1A=',
    },
  };

  // http.post(url, payload, params);
  var res = http.post(url, payload, params);
  // console.log(res.body);

  // console.log(JSON.stringify(res));
  check(res, {
    'status is 200': (r) => r.status === 200,
  });
}
