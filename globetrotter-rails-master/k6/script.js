import http from 'k6/http';
import { check, sleep } from 'k6';

export let options = {
  stages: [
    { duration: '30s', target: 20 },
    { duration: '1m30s', target: 10 },
    { duration: '1m30s', target: 100 },
    { duration: '20s', target: 0 },
  ],
};

const params = {
  headers: {
        'Authorization': 'Basic ' + __ENV.BASIC_AUTH,
  },
};

export default function () {
  http.get('https://www.theglobetrotters.live?tz=Europe/Paris', params);
}
