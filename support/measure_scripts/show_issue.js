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

  commands.meta.setTitle("Test Issue List and Detail Workflows");
  commands.meta.setDescription(
    "Tests the workflow of loading own issue list, go to issue detail, write somethin in notes box and go back to list"
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

  await commands.measure.start("IssueShow");

  await click_simulation(`a[data-qa-selector="issues_shortcut_button"]`);

  await click_simulation(".issue-title-text a");

  await commands.wait.bySelector("#note-body", 35000);

  await commands.scroll.toBottom(100);

  await commands.addText.byId("Test Comment", "note-body");

  await click_simulation(`a[data-qa-selector="issues_shortcut_button"]`);

  await commands.wait.bySelector(".issue-title-text a", 35000);

  await commands.measure.stop();

  return;
};
