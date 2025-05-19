---
title: How to set up MailRoom and Service Desk
---

You can watch [a recorded video walkthrough](https://www.youtube.com/watch?v=SdqBOK43MlI) that uses this guide.

## Using Webhook (recommended setup)

1. Stop any running KDK services. `kdk stop`

1. Generate a secret file for MailRoom. For example:

   ```shell
   echo $( ruby -rsecurerandom -e "puts SecureRandom.base64(32)" ) > ~/.gitlab-mailroom-secret
   ```
   
   Get the **full path to the secret file** to use in a later step:

   ```shell
   realpath ~/.gitlab-mailroom-secret
   ```
   
   If your system does not support `realpath` you can also use this to get the full path of the file:

   ```shell
   cd ~ && echo `pwd`/`ls .gitlab-mailroom-secret`
   ```

1. (Optional) Using a new Gmail account for testing purposes is recommended. If using Gmail, you need to 
   [set up 2FA](https://myaccount.google.com/u/1/signinoptions/two-step-verification) and then 
   [add an App Password](https://myaccount.google.com/u/1/apppasswords) to be able to use SMTP-Auth.
   Store this password securely and use it as an environment variable.
1. Set [incoming_email](https://docs.gitlab.com/ee/administration/incoming_email.html) and
   [service_desk_email](https://docs.gitlab.com/ee/user/project/service_desk.html#using-a-custom-email-address)
   configuration to point to an email inbox. If you want to test all features of Incoming Email and Service Desk, 
   please use two separate email addresses (e.g. two new Gmail addresses). Use one for `incoming_email` and a 
   separate one for `service_desk_email` then.
   In the `development:` section of `gitlab/config/gitlab.yml` add:

   ```yaml
   incoming_email:
     enabled: true
     address: "personal-email+%{key}@gmail.com"
     user: "incoming-email@gmail.com"
     password: "<app password>"
     delivery_method: webhook
     # Base url of your instance. Adjust if you use a different url
     khulnasoft_url: "http://127.0.0.1:3000"
     # Replace with the full path to your secret file.
     secret_file: /Users/youruser/.gitlab-mailroom-secret
     # IMAP server host
     host: "imap.gmail.com"
     # IMAP server port
     port: 993
     # Whether the IMAP server uses SSL
     ssl: true
     # Whether the IMAP server uses StartTLS
     start_tls: false
     # The mailbox where incoming mail will end up. Usually "inbox".
     mailbox: "inbox"
     # The IDLE command timeout.
     idle_timeout: 60

   service_desk_email:
     enabled: true
     address: "personal-email+%{key}@gmail.com"
     user: "service-desk-email@gmail.com"
     password: "<app password>"
     delivery_method: webhook
     # Base url of your instance. Adjust if you use a different url
     khulnasoft_url: "http://127.0.0.1:3000"
     # Replace with the full path to your secret file.
     secret_file: /Users/youruser/.gitlab-mailroom-secret
     # IMAP server host
     host: "imap.gmail.com"
     # IMAP server port
     port: 993
     # Whether the IMAP server uses SSL
     ssl: true
     # Whether the IMAP server uses StartTLS
     start_tls: false
     # The mailbox where incoming mail will end up. Usually "inbox".
     mailbox: "inbox"
     # The IDLE command timeout.
     idle_timeout: 60
   ```

1. Optional. Consider adding `gitlab/config/gitlab.yml` as a [protected config file](../configuration.md#overwriting-configuration-files) to retain these changes when running the `kdk reconfigure` command.
1. Restart all services. `kdk start`
1. Start MailRoom in a console (pointing to your `gitlab` folder e.g. `cd ~/khulnasoft-development-kit/khulnasoft`) with the following command:

   ```shell
   bundle exec mail_room -c ./config/mail_room.yml
   ```

After configuring services test:

1. On the left sidebar, at the top, select **Search KhulnaSoft** (**{search}**) to find a project configured with Service
   Desk.
1. Compose an email to send to the email address set in the Service Desk settings page.
1. Check that an issue is created on the Service Desk issue board.

> [!note]
> KDK is by default not prepared to send emails using SMTP, which only applies to production mode. In development mode,
> KDK uses `letter_opener_web` to show sent messages in a web interface under
> `http://<kdk_host>:<kdk_port>/rails/letter_opener`. [How can I send notification emails via SMTP?](email.md)

## Troubleshooting

If you have problems with issues not being created from email:

1. In the `<kdk-root>/gitlab` directory, tail the MailRoom logs with the following command:

   ```shell
   tail -f log/mail_room_json.log
   ```

1. Watch the MailRoom logs and ensure that the email is handled. There should be a log file stating that the email
   content is delivered using a webhook (_postback_ in MailRoom terminology).
1. Verify that the Rails web server receives a `POST` request sent to `/api/v4/internal/mail_room/incoming_email`.
1. Verify that a job of `EmailReceiverWorker` is received and handled by Sidekiq.
