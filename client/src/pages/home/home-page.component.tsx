import React from 'react';
import GoogleLogin, { GoogleLoginResponse, GoogleLoginResponseOffline } from 'react-google-login';

import { googleOauthClientId } from '../../constants';

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

function onGoogleResponse(response: GoogleLoginResponse | GoogleLoginResponseOffline) {
  console.log(response);
}

function onGoogleFailure(error: unknown) {
  console.error(error);
}