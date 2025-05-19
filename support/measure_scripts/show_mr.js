const login_util = require("./utils/login_measure_util");
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
  await login_util(baseURL, context, commands);
  await commands.navigate(baseURL + "/-/profile");

  driver.manage().addCookie({ name: "perf_bar_enabled", value: "false" });

  await commands.js.run(
    'document.body.innerHTML = ""; document.body.style.backgroundColor = "white";'
  );

  await commands.navigate(baseURL + "/explore");

  await mouse_utils.injectFakeMouseCursor(commands);

  await commands.measure.start("MRJourney");

  await click_simulation(`a[data-qa-selector="merge_requests_shortcut_button"]`);

  await click_simulation(`.js-assigned-mr-count`);

  await click_simulation('.merge-request-title-text a');

  // await commands.wait.bySelector("a[data-user-id='4']", 35000);
  await commands.wait.bySelector("#note-body", 35000);

  await commands.scroll.toBottom(100);

  await commands.addText.byId("Test Comment", "note-body");

  // await click_simulation('.js-comment-submit-button .btn-confirm');

  // await commands.wait.bySelector("a[data-username='root']", 3000);

  await commands.wait.byTime(300);

  await click_simulation('a[data-target="#diffs"]');

  await commands.wait.byId("a60e2382fd0c34cb06177a3d7034264e22531192_5_5", 10000);

  await commands.scroll.byPages(4);

  await commands.mouse.moveTo.bySelector('#b4f82e18a5b8441d94c7d9f1e162460a01839558_42_41');

  await commands.wait.byTime(10);

  await commands.click.bySelector('#b4f82e18a5b8441d94c7d9f1e162460a01839558_42_41 .js-add-diff-note-button');

  await commands.wait.byTime(10);

  await commands.measure.stop();

  return;
};
