module.exports = async function (baseUrl, context, commands) {
  // We start by navigating to the login page.
  await commands.navigate(baseUrl + '/users/sign_in');

  try {
    console.log('Starting Login')

    const userName = 'root'; // context.options.khulnasoft.user;
    const password = '5iveL!fe'; // context.options.khulnasoft.password;

    await commands.addText.bySelector(userName, '[data-qa-selector="login_field"]');
    await commands.addText.bySelector(password, '[data-qa-selector="password_field"]');

    // Click the sign in button
    await commands.click.bySelectorAndWait('[data-qa-selector="sign_in_button"]');

    // Wait for the user menu to appear, then we know we're logged in
    await commands.wait.byXpath('//*[@data-qa-selector="user_menu"]', 10000);

    return true;
  } catch (e) {
    // We try/catch so we will catch if the the input fields can't be found
    context.log.error(e);
  }
};
