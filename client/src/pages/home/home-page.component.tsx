import { has } from 'lodash';
import React from 'react';
import GoogleLogin, { GoogleLoginResponse, GoogleLoginResponseOffline } from 'react-google-login';

import { googleOauthClientId } from '../../constants';
import { fetchApiObservable } from '../../utils/fetch';

export function HomePageComponent() {
  return (
    <div className='container text-center'>
      <div className='col-8 mt-5 offset-2'>
        <p>Welcome to Boardr!</p>
        <GoogleLogin
          clientId={googleOauthClientId}
          buttonText='Login'
          onSuccess={onGoogleResponse}
          onFailure={onGoogleFailure}
          cookiePolicy={'single_host_origin'}
        />
      </div>
    </div>
  );
}

function onGoogleResponse(res: GoogleLoginResponse | GoogleLoginResponseOffline) {
  if (!isGoogleLoginResponse(res)) {
    return;
  }

  console.log('@@@ google ID', res.googleId);
  fetchApiObservable({
    method: 'POST',
    url: '/api/auth/google',
    body: {
      tokenId: res.tokenId
    }
  }).subscribe(result => console.log('@@@ result', result), err => console.error('@@@ error', err));
}

function onGoogleFailure(error: unknown) {
  console.error(error);
}

function isGoogleLoginResponse(value: unknown): value is GoogleLoginResponse {
  return value !== null && has(value, 'tokenId');
}