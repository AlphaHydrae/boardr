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

  fetchApiObservable({
    method: 'PUT',
    url: `/api/identities/google:${res.googleId}`,
    headers: {
      Authorization: `Bearer ${res.tokenId}`
    }
  }).subscribe(result => console.log('@@@ result', result), err => console.error('@@@ error', err));
}

function onGoogleFailure(error: unknown) {
  console.error(error);
}

function isGoogleLoginResponse(value: any): value is GoogleLoginResponse {
  return value !== null &&
    typeof value === 'object' &&
    typeof value.googleId === 'string' &&
    typeof value.tokenId === 'string';
}