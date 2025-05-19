const mouse_utils = require("./utils/mouse_utils");

const baseURL = "http://host.docker.internal:3000";
const baseRepo = "/flightjs/Flight";

module.exports = async function (context, commands) {
  // we fetch the selenium webdriver from context
  const webdriver = context.selenium.webdriver;
  const driver = context.selenium.driver;

  const click_simulation = async (css_path) => {
    await mouse_utils.moveToAndClickElement(
      css_path,
      commands,
      driver,
      webdriver
    );
  };

  commands.meta.setTitle("Test Repository Browser Workflows");
  commands.meta.setDescription(
    "Tests the workflow of loading a project and then clicking through to a file 2 directories deep"
  );

  // Preloading and pre-setting the performance bar cookie
  await commands.navigate(baseURL + "/users/sign_in");
  driver.manage().addCookie({ name: "perf_bar_enabled", value: "false" });

  // Reset display
  await commands.js.run(
    'document.body.innerHTML = ""; document.body.style.backgroundColor = "white";'
  );

  await commands.navigate(baseURL + "/explore");
  await commands.wait.byPageToComplete();
  await commands.wait.byTime(3000);

  await mouse_utils.injectFakeMouseCursor(commands);

  // Lets start measuring
  await commands.measure.start("RepoJourney");

  await click_simulation(`a[href="${baseRepo}"]`);

  await click_simulation('a[href="/flightjs/Flight/-/tree/master/test"]');

  await click_simulation('a[href="/flightjs/Flight/-/tree/master/test/spec"]');

  await click_simulation(
    'a[href="/flightjs/Flight/-/blob/master/test/spec/attribute_spec.js"]'
  );

  await click_simulation('a[href="/flightjs/Flight/-/tree/master/test/spec"]');

  await click_simulation(
    'a[href="/flightjs/Flight/-/blob/master/test/spec/constructor_spec.js"]'
  );

  // Lets wait for text in the actual file
  await commands.wait.bySelector("#LC34", 35000);

  return await commands.measure.stop();
};
