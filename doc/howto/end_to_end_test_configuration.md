---
title: Debugging Automation Tests
---

There are multiple ways of approaching debugging a failing test case. Each method has its advantages and
disadvantages, also some methods are dependent on the IDE that you are using.

This document shows you some of the different approaches used across the team and help you get set up for debugging.

## RubyMine

[RubyMine](https://www.jetbrains.com/ruby/) is available from JetBrains, RubyMine is a full IDE for Ruby and
Rails development. Using RubyMine has many benefits, such as a comprehensive suite of tools designed for
debugging. When using these tools, it becomes possible to add breakpoints, step through code, inspect variables during
runtime and much more.

### Creating a Run/Debug Configuration in RubyMine

The different setup instructions below are written from the perspective of running the tests from within the KDK
repository. The URL can always be modified to point to any KhulnaSoft instance for testing and the local paths could be
changed to use the KhulnaSoft repository instead of the KDK.

All environment variables mentioned should be entered as a semicolon separated list. The full list of
[supported KhulnaSoft environment variables](https://gitlab.com/gitlab-org/gitlab-qa/-/blob/master/docs/what_tests_can_be_run.md#supported-gitlab-environment-variables)
 can be used when setting up either of the RSpec configurations.

Both sets of instructions require that you select the Ruby SDK **qa**. If this option is not available, you need to
close the project and open it again from `<Path to KDK folder/gitlab/qa`. This is a temporary step to get the **qa**
option to appear. You do not need to open the project from this folder every time.

#### Starting tests using the RubyMine **Run** menu

The steps below set up a new configuration with RubyMine that allows you to Run/Debug tests from the RubyMine
**Run** menu.

1. Select **Edit Configurations...** from the **Run** menu
1. Select the **+** icon and select **Ruby**
1. Give the new configuration a meaningful name
1. Fill in the **Configuration** tab with the following
   - Ruby script: `<Path to KDK folder>/gitlab/qa/bin/qa`
   - Script arguments: `Test::Instance::All <KhulnaSoft URL> -- qa/specs/features/browser_ui/1_manage/login/log_in_spec.rb`
   - Working directory: `<Path to KDK folder>/gitlab/qa`
   - Environment variables: Optional
     - If you'd like to see your script run; `WEBDRIVER_HEADLESS=false`
     - If you have a token to use, you can save time from creating one; `KHULNASOFT_QA_ACCESS_TOKEN=<token>`
   - Ruby SDK: Use project SDK: `qa`
1. Select the **Bundler** tab and check the box for **Run the script in context of the bundle**
1. Save

Following these steps creates a new configuration that runs all the tests in the `log_in_spec.rb` feature file.
Using this approach means you need to create a new configuration for each different test file or change the original
configuration by editing step 4 to point to the new file. This allows you to have different configurations for each
file such as a different KhulnaSoft URL or different environment variables.

Another approach is to alter step 4 and enter the following script Arguments.

```ruby
Test::Instance::All <KhulnaSoft URL> -- --tag focus
```

This now runs any tests that have the `:focus` tag, by default this is none. To start debugging, you
need to add the `:focus` tag to the test. Running the new configuration picks up the newly tagged test.

> Be sure to remove the tags when finished.

It is recommended to use the `:focus` tag for debugging because there is a specific
[RuboCop Cop](https://www.rubydoc.info/gems/rubocop-rspec/RuboCop/Cop/RSpec/Focus) to detect its use. This helps
to ensure that the tag is removed when debugging is complete.

To run the new configuration, you need to select it from the drop down menu in the top right corner of RubyMine. Once
selected, press either the run or debug buttons next to it to start the tests.

#### Starting tests using the RubyMine Gutter

The RubyMine Gutter refers to the space between the code editor and the line numbers. If you click in this space next
to a test, then the options to either run or debug the test appear. By default, these options do not work until we
configure them to work with our framework.

Making the below changes alters the template that RubyMine uses when creating RSpec configurations. This means that
any RSpec test you try to run for the first time creates a template with these settings. As a result, any tests that
are outside of the `gitlab/qa/qa/specs` do not work with this set up. For other tests such as `gitlab/spec`, you
need to alter the configuration after it is created.

1. Select **Edit Configurations...** from the **Run** menu
1. Expand the **Templates** option and select the **RSpec** template
1. Fill in the **Configuration** tab with the following:
   - Enable the "Use custom RSpec runner script" option and set it to `<Path to KDK folder>/gitlab/qa/bin/rubymine`
   - Working directory: `<Path to KDK folder>/gitlab/qa`
   - Environment variables:
     - URL for KhulnaSoft, this is a mandatory variable; `KHULNASOFT_URL=<KhulnaSoft URL>`
     - If you'd like to see your script run; `WEBDRIVER_HEADLESS=false`
     - If you have a token to use, you can save time from creating one; `KHULNASOFT_QA_ACCESS_TOKEN=<token>`
   - Ruby SDK: Use project SDK: `qa`
1. Select the **Bundler** tab and check the box for **Run the script in context of the bundle**
1. Save

This enables the ability to run or debug any of the automation tests from the RubyMine Gutter.
