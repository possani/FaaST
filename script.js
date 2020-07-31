import http from 'k6/http';
import { sleep } from 'k6';

export let options = {
  insecureSkipTLSVerify: true,
  vus: 10,
  duration: '60m',
};

export default function () {
  var url = `https://${__ENV.SERVER_IP}:31001/api/v1/namespaces/guest/actions/${__ENV.SCRIPT}?blocking=true&result=true`;

  var payload = JSON.stringify({});

  var params = {
    timeout: 90000,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Basic MjNiYzQ2YjEtNzFmNi00ZWQ1LThjNTQtODE2YWE0ZjhjNTAyOjEyM3pPM3haQ0xyTU42djJCS0sxZFhZRnBYbFBrY2NPRnFtMTJDZEFzTWdSVTRWck5aOWx5R1ZDR3VNREdJd1A=',
    },
  };

  let res = http.post(url, payload, params);
  console.log(res.body);
}
