import { faGithub } from '@fortawesome/free-brands-svg-icons';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import React, { Fragment } from 'react';
import { Nav, Navbar as BootstrapNavbar, OverlayTrigger, Tooltip } from 'react-bootstrap';
import { LinkContainer } from 'react-router-bootstrap';

export interface NavbarStateProps {
  readonly ready: boolean;
}

export function Navbar(props: NavbarStateProps) {
  return (
    <BootstrapNavbar bg='light' className='mb-3' expand='lg'>
      <LinkContainer to={'/'}>
        <BootstrapNavbar.Brand>Boardr</BootstrapNavbar.Brand>
      </LinkContainer>
      {props.ready && (
        <Fragment>
          <BootstrapNavbar.Toggle aria-controls='navbar' />
          <BootstrapNavbar.Collapse id='navbar'>
            <Nav className='ml-auto'>
              <OverlayTrigger
                overlay={(
                  <Tooltip id='github'>Fork me on GitHub</Tooltip>
                )}
                placement='left'
              >
                <a className='text-secondary' href='https://github.com/AlphaHydrae/boardr' rel='noopener noreferrer' target='_blank'>
                  <FontAwesomeIcon icon={faGithub} />
                </a>
              </OverlayTrigger>
            </Nav>
          </BootstrapNavbar.Collapse>
        </Fragment>
      )}
    </BootstrapNavbar>
  );
}