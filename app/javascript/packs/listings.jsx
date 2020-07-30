import { h, render } from 'preact';
import { Listings } from '../listings/listings';
import { getQueryParams } from '../listings/utils';

function loadElement() {
  const root = document.getElementById('listings-index-container');

  if (root) {
    const {
      displayedlisting = null,
      category = '',
      allcategories = null,
      listings = null,
    } = root.dataset;
    const params = getQueryParams();
    const tags = params.t ? params.t.split(',') : [];
    const query = params.q || '';

    render(
      <Listings
        allCategories={JSON.parse(allcategories)}
        category={category}
        openedListing={JSON.parse(displayedlisting)}
        listings={JSON.parse(listings)}
        tags={tags}
        query={query}
      />,
      root,
    );
  }
}

window.InstantClick.on('change', () => {
  loadElement();
});

loadElement();
