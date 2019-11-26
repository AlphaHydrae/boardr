import React, { Fragment } from 'react';
import { Container } from 'react-bootstrap';

import 'bootstrap/dist/css/bootstrap.css';

import { NavbarContainer } from './components/navbar/navbar.container';
import { Routes } from './routes';

export interface AppStateProps {
  readonly ready: boolean;
}

export function App(props: AppStateProps) {
  return (
    <Fragment>
      <NavbarContainer />
      <Container className='mb-3' fluid={true}>
        {props.ready && <Routes />}
      </Container>
    </Fragment>
  );
}
