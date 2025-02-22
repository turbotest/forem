describe('Hiding/unhiding comments on an article', () => {
  beforeEach(() => {
    cy.testSetup();
    cy.fixture('users/adminUser.json').as('user');

    cy.get('@user').then((user) => {
      cy.loginAndVisit(user, '/admin_mcadmin/test-article-slug');
    });
  });

  describe('Admin visits the article authored by them', () => {
    it('Hides a comment and then unhides it from the same screen', () => {
      cy.findByRole('button', { name: 'Toggle dropdown menu' }).click();
      cy.findByRole('link', { name: "Hide Admin McAdmin's comment" }).click();
      cy.findByRole('button', { name: 'Toggle dropdown menu' }).should(
        'not.be.visible',
      );
      cy.findByRole('img', { name: 'Expand' }).click();
      cy.findByRole('button', { name: 'Toggle dropdown menu' }).click();
      cy.findByRole('link', { name: "Unhide Admin McAdmin's comment" }).click();
      cy.findByRole('img', { name: 'Expand' }).should('not.exist');
    });
  });
});
