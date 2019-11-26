import { connect, MapStateToProps } from 'react-redux';

import { selectReady } from '../../concerns/control/control.selectors';
import { AppState } from '../../store/state';
import { Navbar, NavbarStateProps } from './navbar.component';

const mapStateToProps: MapStateToProps<NavbarStateProps, {}, AppState> = state => ({
  ready: selectReady(state)
});

const mapDispatchToProps = () => ({});

export const NavbarContainer = connect(mapStateToProps, mapDispatchToProps)(Navbar);