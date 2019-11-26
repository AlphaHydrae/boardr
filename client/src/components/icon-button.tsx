import { IconProp } from '@fortawesome/fontawesome-svg-core';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import React, { ReactNode } from 'react';
import { Button, ButtonProps, OverlayTrigger, Tooltip } from 'react-bootstrap';

export interface IconButtonProps extends ButtonProps, React.ComponentPropsWithoutRef<'button'> {
  readonly children?: ReactNode;
  readonly icon?: IconProp;
  readonly id: string;
  readonly tooltip: string;
}

export function IconButton(props: IconButtonProps) {

  const { children, icon, id, tooltip, ...rest } = props;

  return (
    <OverlayTrigger
      overlay={(
        <Tooltip id={`${id}-tooltip`}>
          {tooltip}
        </Tooltip>
      )}
    >
      <Button {...rest}>
        {icon && <FontAwesomeIcon icon={icon} />}
        {children && props.icon && ' '}
        {children}
      </Button>
    </OverlayTrigger>
  );
}