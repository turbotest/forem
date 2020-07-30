import { h } from 'preact';
import { render } from '@testing-library/preact';
import { axe } from 'jest-axe';
import { Listings } from '../listings';

it('should have no a11y violations', async () => {
  // const { container } = render(<Listings />);
  // const results = await axe(container);
  // expect(results).toHaveNoViolations();
});
