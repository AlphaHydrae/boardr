import { connect } from 'react-redux';

import { HomePageComponent } from './home-page.component';

const mapStateToProps = () => ({});
const mapDispatchToProps = () => ({});

export const HomePageContainer = connect(
  mapStateToProps,
  mapDispatchToProps
)(HomePageComponent);