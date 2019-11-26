import React from 'react';
import { Route, Switch } from 'react-router-dom';

import { HomePageContainer } from './pages/home/home-page.container';

export function Routes() {
  return (
    <Switch>
      <Route path='/' exact={true} component={HomePageContainer} />
    </Switch>
  );
}