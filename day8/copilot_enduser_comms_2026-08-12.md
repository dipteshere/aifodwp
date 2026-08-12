# Copilot End-User Communications
**Date:** 2026-08-12  
**Prepared by:** DWP Digital Workplace Support  

Each message below is written for the end user who raised the ticket. Copy and send the relevant section directly.

---

## Ticket 1 — Finance lead: Cannot summarise Q3 board pack in SharePoint

**To:** Finance Lead  
**Subject:** Re: Copilot unable to summarise board pack

Hi,

Thank you for getting in touch. We've looked into this and we don't believe there is a fault with Copilot.

The most likely reason is that the Q3 board pack has a **sensitivity label** applied to it — for example, "Highly Confidential" or "Confidential - Board Only". These labels are there to protect sensitive documents, and one of the things they can do is prevent Copilot from reading or summarising the file, even when you yourself can open it. This is a deliberate security control, not an error.

**What happens next:**

1. Open the board pack in SharePoint and look at the coloured label bar at the top of the document. Let us know what label is shown.
2. If a sensitivity label is the cause, you will need to work with your data owner or information governance team to discuss whether an exception or a different approach is appropriate.
3. We are not able to override sensitivity labels on your behalf — they are set by your organisation's security policy.

If the file has no sensitivity label and the problem continues, please reply and we will investigate further.

Thanks,  
DWP Digital Workplace Support

---

## Ticket 2 — New hire: Copilot does not know about recent emails

**To:** New Starter  
**Subject:** Re: Copilot not showing my emails

Hi, and welcome to the team!

Thank you for letting us know. This is completely expected when an account is brand new and is not a fault.

When a new Microsoft 365 account is set up, it takes between **24 and 72 hours** for the system to index your emails, calendar, and files so that Copilot can use them. Until that indexing is complete, Copilot simply has nothing to work from.

**What happens next:**

1. Please wait until you have been set up for at least two to three working days, then try again.
2. If Copilot still cannot see your emails after 72 hours, please contact us again and we will check that your Copilot licence has been correctly assigned to your account.

No action is needed from you right now — this should resolve itself shortly.

Thanks,  
DWP Digital Workplace Support

---

## Ticket 3 — HR manager: "I don't have access to that content" on salary review spreadsheet

**To:** HR Manager  
**Subject:** Re: Copilot access error on salary spreadsheet

Hi,

Thank you for raising this. The message "I don't have access to that content" is not a general error — it is Copilot telling you precisely that it has been **blocked from reading that file by a security policy**.

Salary and pay review data almost always carries a **Highly Confidential sensitivity label**, which is specifically designed to stop tools like Copilot from processing that information. This is working as intended — it is a protection for your colleagues' personal and financial data.

**What happens next:**

1. Open the spreadsheet in Excel and check the sensitivity label shown in the toolbar at the top.
2. If it is labelled Highly Confidential or similar, Copilot cannot and should not access it. This is by design.
3. If you need to work with this data using AI assistance, please raise this with your Information Governance or HR Systems team, who can advise on approved methods.

We would not recommend attempting to remove or change the sensitivity label yourself.

Thanks,  
DWP Digital Workplace Support

---

## Ticket 4 — Sales rep: Copilot cannot find client contract from external org

**To:** Sales Representative  
**Subject:** Re: Copilot unable to find external client contract

Hi,

Thank you for raising this. We have looked into the issue and this is a **known limitation** of Microsoft Copilot, not a fault.

Copilot can only search and work with files that are stored in **our organisation's own Microsoft 365 environment**. Files that live in another company's system — even when shared with you via a guest link — are outside the boundary that Copilot is allowed to reach. This is a Microsoft platform boundary that applies to all organisations.

**What happens next:**

1. If you need Copilot to work with this contract, ask the other organisation to send you the file as an attachment or share it directly into a folder in **our** SharePoint or OneDrive.
2. Once the file is saved in our environment, Copilot will be able to find and summarise it.
3. If the file cannot be moved for contractual or security reasons, you will need to work with it manually.

We are sorry we cannot offer a quicker fix here — this is a platform boundary we cannot change.

Thanks,  
DWP Digital Workplace Support

---

## Ticket 5 — Finance team: Copilot stopped working this morning (all users)

**To:** Finance Team / IT Admin  
**Subject:** Re: Copilot not working for Finance team

Hi,

Thank you for alerting us to this urgently. We are treating this as a priority and are investigating now.

When Copilot stops working for an entire team at the same time, the most common causes are:

- A change to **licence assignments** for the Finance group (which can happen automatically overnight via policy updates)
- A **service issue** on Microsoft's side affecting our tenant

**What we are doing:**

1. We are checking the Microsoft 365 Service Health dashboard for any active Copilot incidents.
2. We are verifying that Copilot licences are still correctly assigned to all Finance team accounts.
3. We will update you as soon as we have a confirmed cause and estimated resolution time.

**What you can do in the meantime:**  
Please continue working as normal without Copilot. We will notify the team as soon as the service is restored.

We aim to have an update for you within **two hours**.

Thanks,  
DWP Digital Workplace Support

---

## Ticket 6 — Manager: Copilot found a file I did not know about

**To:** Manager  
**Subject:** Re: Copilot surfaced an unexpected file

Hi,

Thank you for flagging this. We want to reassure you: **Copilot has not done anything it should not have done**.

Copilot only ever shows you files that you already have permission to access. It cannot see files belonging to other people unless you have been given access to them. In this case, it sounds like your account has access to a folder — possibly through a team site, a shared drive, or an inherited permission — that you had forgotten about.

**What this means:**

- No unauthorised access has taken place.
- Copilot surfacing the file is a sign that it is working correctly.

**What you may want to do:**

1. If you are concerned about having access to that folder, speak to your line manager or the folder owner about whether your access is still appropriate.
2. If you would like us to review your permissions and tidy up any access you no longer need, please reply and we can arrange that with your IT admin.

This is actually a good opportunity to review your folder permissions — many people find they have accumulated access over time that is no longer needed.

Thanks,  
DWP Digital Workplace Support

---

## Ticket 7 — Analyst: Copilot gives only generic answers, ignores internal content

**To:** Analyst  
**Subject:** Re: Copilot not using internal SharePoint content

Hi,

Thank you for getting in touch. This is a useful thing to flag, and we do not believe it is a fault with Copilot itself.

Copilot can only use internal content that it has **permission to access and has indexed**. If it is giving you only generic answers, it is most likely because one of the following applies:

- You may not have access to the SharePoint sites where the relevant content lives
- Those sites may not yet have been indexed for your account
- A configuration setting may be preventing Copilot from searching SharePoint content

**What happens next:**

1. Please try opening one of the internal SharePoint sites you would expect Copilot to use, directly in your browser. If you cannot get in, a permissions issue is the cause — contact us and we will check your site access.
2. If you can open the sites fine but Copilot still ignores them, please reply with examples of the sites and the types of questions you are asking. This will help us investigate the configuration.
3. In the meantime, you can help Copilot by **pasting the relevant content or sharing a file link** directly in your Copilot prompt as a workaround.

Thanks,  
DWP Digital Workplace Support

---

## Ticket 8 — Executive assistant: Copilot cannot see shared mailbox calendar

**To:** Executive Assistant  
**Subject:** Re: Copilot unable to access shared mailbox calendar

Hi,

Thank you for raising this. This is a known limitation rather than a fault, and we can explain what is happening.

Microsoft Copilot in Outlook is designed to work with **your own primary mailbox and calendar**. Shared mailboxes — even ones you manage on behalf of someone else — require additional configuration and, in most cases, **their own Copilot licence** before Copilot can process their content.

**What happens next:**

1. We will check whether the shared mailbox has a Copilot licence assigned. If it does not, we can raise this with the licencing team to assess whether one can be allocated.
2. While this is being looked into, you can still use Copilot for your own primary mailbox and calendar as normal.
3. For the director's calendar, you may need to continue managing and summarising appointments manually until the licencing question is resolved.

We will aim to come back to you with a decision on the licence within **three to five working days**.

Thanks,  
DWP Digital Workplace Support
