# Sampul App - User Acceptance Test (UAT) Guide

## INTRODUCTION

This document is a test script for User Acceptance Test (UAT) of the Sampul mobile application. Testers will perform testing based on user experience and predefined test scenarios to ensure the app works as expected.

**About Sampul App:**
Sampul is an estate planning application for Malaysian users. It helps users manage their estate planning documents including Trust Funds, Hibah (Islamic will), traditional Wills, assets, family members, and provides AI-powered guidance.

---

## TESTING OBJECTIVES

The primary goal of this User Acceptance Test is to verify that the Sampul mobile application meets all functional requirements and provides a seamless user experience across different devices. Through systematic testing, we aim to identify any issues, validate feature functionality, and ensure the app is ready for production use.

The objectives of this User Acceptance Test are:
- To verify that all features work correctly and meet requirements
- To ensure the mobile application functions properly on different devices
- To identify any bugs, issues, or areas for improvement
- To confirm the app provides a good user experience

---

## EXECUTION OF TESTING

Testers should follow the process outlined below to ensure consistent and thorough testing. Each step is designed to maintain quality and completeness throughout the testing phase.

1. **Receive test script** - You will receive this test script and test account credentials (if needed)
2. **Follow test steps** - Execute testing based on the testing steps provided in each test case
3. **Compare results** - Compare actual results with expected results
4. **Record results** - Mark "Pass" or "Fail" for each test case
5. **Document issues** - For failed tests, provide clear reasons and screenshots
6. **Add comments** - Write any suggestions, bugs, or additional information in the remarks column
7. **Mark incomplete** - If a test cannot be completed, write "KIV" (Keep In View) in remarks

---

## TEST SCENARIO

All testing should be conducted under the following conditions to ensure consistency and reliability of results. These guidelines help maintain uniformity across different testers and testing sessions.

- Use the testing environment provided for mobile application testing
- Log in using the assigned test account credentials
- Test only the features and functions listed in this document
- Follow the test steps exactly as written
- Test on real devices (not just simulators)
- Take screenshots when issues are found

---

## ENTRY CRITERIA

Before testing can begin, certain prerequisites must be met. All items listed below must be satisfied to ensure a smooth and effective testing process.

Before starting testing, ensure:
- ✅ You can log in to the Sampul mobile application
- ✅ You have a test account with proper credentials
- ✅ The app is installed and running on your device
- ✅ You have internet connectivity
- ✅ You understand the testing process

---

## EXIT CRITERIA

The testing phase is considered complete when all criteria listed below have been satisfied. These conditions ensure that comprehensive testing has been performed and all findings have been properly documented.

Testing is complete when:
- ✅ All test cases have been executed
- ✅ All results have been recorded (Pass/Fail)
- ✅ All issues have been documented with screenshots
- ✅ Test report has been submitted

---

## TESTER INFORMATION

Please provide the following information to help track testing conditions and identify any device-specific or environment-related issues. Accurate information is essential for analyzing test results and troubleshooting problems.

| Field | Details |
|-------|---------|
| Name | |
| Position | |
| Department | |
| Date | |
| Device Type & Model | |
| OS Version | |
| Connectivity | WiFi / Mobile Data |
| Location | |
| Time Start | |
| Time Finish | |

---

## TRACEABILITY MATRIX

The traceability matrix below provides a comprehensive overview of all test cases organized by module. This matrix helps track feature coverage and ensures all app functionality is thoroughly tested. Each test case is assigned a unique identifier (TC-XX.XX) for easy reference and tracking.

Testing scope covers the following modules:

| No | Module | Test Case ID | Test Case Name |
|----|--------|--------------|----------------|
| 1 | **Authentication** | TC-01.01 | User Registration (Email/Password) |
| | | TC-01.02 | User Login (Email/Password) |
| | | TC-01.03 | Google Sign-In |
| | | TC-01.04 | Forgot Password |
| | | TC-01.05 | Onboarding Flow |
| 2 | **Home & Navigation** | TC-02.01 | Home Screen Display |
| | | TC-02.02 | Navigation Tabs |
| | | TC-02.03 | Quick Actions |
| 3 | **Trust Fund** | TC-03.01 | Create Trust Fund |
| | | TC-03.02 | View Trust Fund Details |
| | | TC-03.03 | Edit Trust Fund |
| | | TC-03.04 | Add Beneficiaries |
| | | TC-03.05 | Add Charity Recipients |
| 4 | **Hibah** | TC-04.01 | Create Hibah |
| | | TC-04.02 | View Hibah Details |
| | | TC-04.03 | Edit Hibah |
| 5 | **Will** | TC-05.01 | Generate Will |
| | | TC-05.02 | View Will Details |
| 6 | **Assets** | TC-06.01 | Add Asset |
| | | TC-06.02 | View Asset List |
| | | TC-06.03 | Edit Asset |
| | | TC-06.04 | Delete Asset |
| 7 | **Family Members** | TC-07.01 | Add Family Member |
| | | TC-07.02 | View Family List |
| | | TC-07.03 | Edit Family Member |
| 8 | **Executors** | TC-08.01 | Create Executor |
| | | TC-08.02 | View Executor List |
| | | TC-08.03 | Edit Executor |
| 9 | **AI Chat** | TC-09.01 | Start Chat Conversation |
| | | TC-09.02 | Send Message & Receive Response |
| | | TC-09.03 | Action Buttons Navigation |
| 10 | **Post-Loss Care** | TC-10.01 | View Checklist |
| | | TC-10.02 | Mark Checklist Items |
| 11 | **Settings** | TC-11.01 | Edit Profile |
| | | TC-11.02 | Change Theme (Light/Dark) |
| | | TC-11.03 | View Billing/Subscription |
| | | TC-11.04 | Logout |

---

## DETAILED TEST CASES

The following test cases provide step-by-step instructions for testing each module. Each test case includes prerequisites, detailed actions, expected results, and space to record actual findings. Testers should follow each case methodically and document all observations.

### MODULE 1: AUTHENTICATION

User registration, login, and authentication form the foundation of app access. These features must function flawlessly as they are the first interaction point for all users. Testing should verify smooth account creation, secure login processes, and proper error handling.

#### TC-01.01: User Registration (Email/Password)
**Prerequisite:** App is installed and opened

| Step | Action | Expected Result |
|------|--------|----------------|
| 1 | Open Sampul app | App opens to login screen |
| 2 | Tap "Sign Up" or "Create Account" | Registration form appears |
| 3 | Enter name, email, and password | Fields accept input |
| 4 | Tap "Create Account" | **Positive:** Account created, user logged in<br>**Negative:** Error message shown if invalid |
| 5 | Check email (if verification enabled) | Verification email received |

**Actual Result:** Pass / Fail  
**Remarks:** (Add screenshot if failed)

---

#### TC-01.02: User Login (Email/Password)
**Prerequisite:** User has registered account

| Step | Action | Expected Result |
|------|--------|----------------|
| 1 | Open Sampul app | Login screen appears |
| 2 | Enter registered email and password | Fields accept input |
| 3 | Tap "Login" | **Positive:** User logged in, navigates to home<br>**Negative:** Error if wrong credentials |
| 4 | Verify user is on home screen | Home screen displays correctly |

**Actual Result:** Pass / Fail  
**Remarks:** (Add screenshot if failed)

---

#### TC-01.03: Google Sign-In
**Prerequisite:** App is installed

| Step | Action | Expected Result |
|------|--------|----------------|
| 1 | Open Sampul app | Login screen appears |
| 2 | Tap "Continue with Google" | Google sign-in screen appears |
| 3 | Select Google account | Google account selection works |
| 4 | Complete Google authentication | User logged in, navigates to home |

**Actual Result:** Pass / Fail  
**Remarks:** (Add screenshot if failed)

---

#### TC-01.04: Forgot Password
**Prerequisite:** User has registered account

| Step | Action | Expected Result |
|------|--------|----------------|
| 1 | Open login screen | Login screen appears |
| 2 | Tap "Forgot Password" | Forgot password screen appears |
| 3 | Enter registered email | Field accepts input |
| 4 | Tap "Send Reset Link" | **Positive:** Reset email sent confirmation<br>**Negative:** Error if email not found |
| 5 | Check email | Password reset email received |

**Actual Result:** Pass / Fail  
**Remarks:** (Add screenshot if failed)

---

#### TC-01.05: Onboarding Flow
**Prerequisite:** New user (first time opening app)

| Step | Action | Expected Result |
|------|--------|----------------|
| 1 | Open app for first time | Onboarding screens appear |
| 2 | Swipe through onboarding screens | All screens display correctly |
| 3 | Tap "Get Started" or "Skip" | User proceeds to login/registration |
| 4 | Complete registration | Onboarding doesn't show again on next login |

**Actual Result:** Pass / Fail  
**Remarks:** (Add screenshot if failed)

---

### MODULE 2: HOME & NAVIGATION

The home screen serves as the central hub of the application, providing quick access to key features and displaying important information at a glance. Navigation between different sections must be intuitive and responsive. Testing should focus on visual presentation, functionality of quick actions, and smooth transitions between screens.

#### TC-02.01: Home Screen Display
**Prerequisite:** User is logged in

| Step | Action | Expected Result |
|------|--------|----------------|
| 1 | Login to app | Home screen displays |
| 2 | Check all elements | Cards, widgets, quick actions visible |
| 3 | Verify no broken images | All images load correctly |
| 4 | Pull down to refresh | Screen refreshes, data updates |

**Actual Result:** Pass / Fail  
**Remarks:** (Add screenshot if failed)

---

#### TC-02.02: Navigation Tabs
**Prerequisite:** User is logged in

| Step | Action | Expected Result |
|------|--------|----------------|
| 1 | Tap each navigation tab | Each tab navigates correctly |
| 2 | Verify tabs: Home, Assets, Family, Chat, Settings | All tabs work and show correct screens |
| 3 | Check active tab indicator | Current tab is highlighted |

**Actual Result:** Pass / Fail  
**Remarks:** (Add screenshot if failed)

---

#### TC-02.03: Quick Actions
**Prerequisite:** User is on home screen

| Step | Action | Expected Result |
|------|--------|----------------|
| 1 | Locate quick action buttons | Buttons are visible and tappable |
| 2 | Tap each quick action | Each action navigates to correct screen |
| 3 | Verify navigation | User reaches intended feature |

**Actual Result:** Pass / Fail  
**Remarks:** (Add screenshot if failed)

---

### MODULE 3: TRUST FUND

Trust funds enable users to allocate assets for beneficiaries and charitable organizations. This module requires thorough testing of all CRUD operations (Create, Read, Update, Delete) to ensure data integrity. Particular attention should be paid to beneficiary and charity recipient management, as these are critical components of trust fund functionality.

#### TC-03.01: Create Trust Fund
**Prerequisite:** User is logged in

| Step | Action | Expected Result |
|------|--------|----------------|
| 1 | Navigate to Trust Management | Trust list screen appears |
| 2 | Tap "Create Trust" or "+" button | Trust creation form appears |
| 3 | Fill in required fields | All fields accept input |
| 4 | Tap "Save" or "Create" | **Positive:** Trust created, success message<br>**Negative:** Validation errors shown |
| 5 | Verify trust appears in list | New trust fund visible in list |

**Actual Result:** Pass / Fail  
**Remarks:** (Add screenshot if failed)

---

#### TC-03.02: View Trust Fund Details
**Prerequisite:** At least one trust fund exists

| Step | Action | Expected Result |
|------|--------|----------------|
| 1 | Navigate to Trust Management | Trust list appears |
| 2 | Tap on a trust fund | Trust details screen opens |
| 3 | Verify all information displays | All trust data shown correctly |
| 4 | Check beneficiaries and charities | All recipients listed correctly |

**Actual Result:** Pass / Fail  
**Remarks:** (Add screenshot if failed)

---

#### TC-03.03: Edit Trust Fund
**Prerequisite:** At least one trust fund exists

| Step | Action | Expected Result |
|------|--------|----------------|
| 1 | Open trust fund details | Details screen appears |
| 2 | Tap "Edit" button | Edit form opens with existing data |
| 3 | Modify fields | Changes are saved in form |
| 4 | Tap "Save" | **Positive:** Changes saved successfully<br>**Negative:** Validation errors if invalid |
| 5 | Verify changes | Updated data displays correctly |

**Actual Result:** Pass / Fail  
**Remarks:** (Add screenshot if failed)

---

#### TC-03.04: Add Beneficiaries
**Prerequisite:** Trust fund is created

| Step | Action | Expected Result |
|------|--------|----------------|
| 1 | Open trust fund details | Details screen appears |
| 2 | Navigate to beneficiaries section | Beneficiaries list/form appears |
| 3 | Add beneficiary information | Form accepts input |
| 4 | Save beneficiary | Beneficiary added to trust |
| 5 | Verify beneficiary appears | New beneficiary listed correctly |

**Actual Result:** Pass / Fail  
**Remarks:** (Add screenshot if failed)

---

#### TC-03.05: Add Charity Recipients
**Prerequisite:** Trust fund is created

| Step | Action | Expected Result |
|------|--------|----------------|
| 1 | Open trust fund details | Details screen appears |
| 2 | Navigate to charity section | Charity form/list appears |
| 3 | Add charity information | Form accepts input |
| 4 | Save charity | Charity added to trust |
| 5 | Verify charity appears | New charity listed correctly |

**Actual Result:** Pass / Fail  
**Remarks:** (Add screenshot if failed)

---

### MODULE 4: HIBAH

Hibah represents an essential estate planning instrument for Muslim users, allowing for the transfer of assets during one's lifetime. Testing should verify that Hibah documents can be created, viewed, and edited accurately, with all information properly stored and displayed according to Islamic principles.

#### TC-04.01: Create Hibah
**Prerequisite:** User is logged in

| Step | Action | Expected Result |
|------|--------|----------------|
| 1 | Navigate to Hibah Management | Hibah list screen appears |
| 2 | Tap "Create Hibah" or "+" button | Hibah creation form appears |
| 3 | Fill in required fields | All fields accept input |
| 4 | Tap "Save" | **Positive:** Hibah created successfully<br>**Negative:** Validation errors shown |
| 5 | Verify hibah appears in list | New hibah visible in list |

**Actual Result:** Pass / Fail  
**Remarks:** (Add screenshot if failed)

---

#### TC-04.02: View Hibah Details
**Prerequisite:** At least one hibah exists

| Step | Action | Expected Result |
|------|--------|----------------|
| 1 | Navigate to Hibah Management | Hibah list appears |
| 2 | Tap on a hibah | Hibah details screen opens |
| 3 | Verify all information displays | All hibah data shown correctly |

**Actual Result:** Pass / Fail  
**Remarks:** (Add screenshot if failed)

---

#### TC-04.03: Edit Hibah
**Prerequisite:** At least one hibah exists

| Step | Action | Expected Result |
|------|--------|----------------|
| 1 | Open hibah details | Details screen appears |
| 2 | Tap "Edit" button | Edit form opens with existing data |
| 3 | Modify fields | Changes are saved in form |
| 4 | Tap "Save" | Changes saved successfully |
| 5 | Verify changes | Updated data displays correctly |

**Actual Result:** Pass / Fail  
**Remarks:** (Add screenshot if failed)

---

### MODULE 5: WILL

Traditional will generation is a critical feature that produces legally binding documents. The will generation process must be accurate and comprehensive, capturing all user-specified information correctly. Testing should validate that generated wills contain complete and accurate information as entered by the user.

#### TC-05.01: Generate Will
**Prerequisite:** User is logged in

| Step | Action | Expected Result |
|------|--------|----------------|
| 1 | Navigate to Will Management | Will screen appears |
| 2 | Tap "Generate Will" or "Create Will" | Will generation form appears |
| 3 | Fill in required information | All fields accept input |
| 4 | Tap "Generate" or "Create" | **Positive:** Will generated successfully<br>**Negative:** Errors if incomplete |
| 5 | Verify will document | Will document/view appears |

**Actual Result:** Pass / Fail  
**Remarks:** (Add screenshot if failed)

---

#### TC-05.02: View Will Details
**Prerequisite:** At least one will exists

| Step | Action | Expected Result |
|------|--------|----------------|
| 1 | Navigate to Will Management | Will list appears |
| 2 | Tap on a will | Will details/document opens |
| 3 | Verify will content | All will information displays correctly |

**Actual Result:** Pass / Fail  
**Remarks:** (Add screenshot if failed)

---

### MODULE 6: ASSETS

Asset management encompasses a wide range of valuable items including real estate, vehicles, investments, and personal property. The system must accurately capture, store, and display all asset information across different asset types. Testing should verify data persistence, proper categorization, and accurate value representation.

#### TC-06.01: Add Asset
**Prerequisite:** User is logged in

| Step | Action | Expected Result |
|------|--------|----------------|
| 1 | Navigate to Assets screen | Asset list appears |
| 2 | Tap "Add Asset" or "+" button | Asset creation form appears |
| 3 | Select asset type | Asset type options available |
| 4 | Fill in asset details | All fields accept input |
| 5 | Tap "Save" | **Positive:** Asset saved successfully<br>**Negative:** Validation errors if invalid |
| 6 | Verify asset appears in list | New asset visible in list |

**Actual Result:** Pass / Fail  
**Remarks:** (Add screenshot if failed)

---

#### TC-06.02: View Asset List
**Prerequisite:** At least one asset exists

| Step | Action | Expected Result |
|------|--------|----------------|
| 1 | Navigate to Assets screen | Asset list appears |
| 2 | Verify all assets display | All assets shown correctly |
| 3 | Check asset information | Asset details visible in list |

**Actual Result:** Pass / Fail  
**Remarks:** (Add screenshot if failed)

---

#### TC-06.03: Edit Asset
**Prerequisite:** At least one asset exists

| Step | Action | Expected Result |
|------|--------|----------------|
| 1 | Open asset from list | Asset details appear |
| 2 | Tap "Edit" button | Edit form opens with existing data |
| 3 | Modify asset information | Changes are saved in form |
| 4 | Tap "Save" | Changes saved successfully |
| 5 | Verify changes | Updated asset data displays correctly |

**Actual Result:** Pass / Fail  
**Remarks:** (Add screenshot if failed)

---

#### TC-06.04: Delete Asset
**Prerequisite:** At least one asset exists

| Step | Action | Expected Result |
|------|--------|----------------|
| 1 | Open asset from list | Asset details appear |
| 2 | Tap "Delete" button | Confirmation dialog appears |
| 3 | Confirm deletion | **Positive:** Asset deleted, removed from list<br>**Negative:** Error if deletion fails |
| 4 | Verify asset removed | Asset no longer in list |

**Actual Result:** Pass / Fail  
**Remarks:** (Add screenshot if failed)

---

### MODULE 7: FAMILY MEMBERS

Family member management allows users to maintain a comprehensive database of family relationships and contact information. This information is crucial for estate planning purposes. Testing should ensure that relationship types are correctly assigned, contact details are accurately stored, and family member data integrates properly with other estate planning features.

#### TC-07.01: Add Family Member
**Prerequisite:** User is logged in

| Step | Action | Expected Result |
|------|--------|----------------|
| 1 | Navigate to Family screen | Family list appears |
| 2 | Tap "Add Family Member" or "+" button | Family member form appears |
| 3 | Fill in name, relationship, contact | All fields accept input |
| 4 | Tap "Save" | **Positive:** Family member added<br>**Negative:** Validation errors if invalid |
| 5 | Verify member appears in list | New family member visible |

**Actual Result:** Pass / Fail  
**Remarks:** (Add screenshot if failed)

---

#### TC-07.02: View Family List
**Prerequisite:** At least one family member exists

| Step | Action | Expected Result |
|------|--------|----------------|
| 1 | Navigate to Family screen | Family list appears |
| 2 | Verify all members display | All family members shown correctly |
| 3 | Check member information | Names, relationships visible |

**Actual Result:** Pass / Fail  
**Remarks:** (Add screenshot if failed)

---

#### TC-07.03: Edit Family Member
**Prerequisite:** At least one family member exists

| Step | Action | Expected Result |
|------|--------|----------------|
| 1 | Open family member from list | Member details appear |
| 2 | Tap "Edit" button | Edit form opens with existing data |
| 3 | Modify information | Changes are saved in form |
| 4 | Tap "Save" | Changes saved successfully |
| 5 | Verify changes | Updated member data displays correctly |

**Actual Result:** Pass / Fail  
**Remarks:** (Add screenshot if failed)

---

### MODULE 8: EXECUTORS

Executors play a vital role in estate administration, responsible for managing and distributing assets according to the user's wishes. The executor management system must accurately capture and maintain executor information, including personal details and assigned responsibilities. Testing should verify that all executor forms function correctly and data is properly associated with the estate.

#### TC-08.01: Create Executor
**Prerequisite:** User is logged in

| Step | Action | Expected Result |
|------|--------|----------------|
| 1 | Navigate to Executor Management | Executor list appears |
| 2 | Tap "Create Executor" or "+" button | Executor creation form appears |
| 3 | Fill in executor information | All fields accept input |
| 4 | Tap "Save" | **Positive:** Executor created<br>**Negative:** Validation errors if invalid |
| 5 | Verify executor appears in list | New executor visible |

**Actual Result:** Pass / Fail  
**Remarks:** (Add screenshot if failed)

---

#### TC-08.02: View Executor List
**Prerequisite:** At least one executor exists

| Step | Action | Expected Result |
|------|--------|----------------|
| 1 | Navigate to Executor Management | Executor list appears |
| 2 | Verify all executors display | All executors shown correctly |
| 3 | Check executor information | Executor details visible |

**Actual Result:** Pass / Fail  
**Remarks:** (Add screenshot if failed)

---

#### TC-08.03: Edit Executor
**Prerequisite:** At least one executor exists

| Step | Action | Expected Result |
|------|--------|----------------|
| 1 | Open executor from list | Executor details appear |
| 2 | Tap "Edit" button | Edit form opens with existing data |
| 3 | Modify information | Changes are saved in form |
| 4 | Tap "Save" | Changes saved successfully |
| 5 | Verify changes | Updated executor data displays correctly |

**Actual Result:** Pass / Fail  
**Remarks:** (Add screenshot if failed)

---

### MODULE 9: AI CHAT

The AI chat assistant provides intelligent guidance for estate planning questions and can facilitate quick navigation through action buttons embedded in responses. Testing should focus on response quality, timing, relevance to user queries, and the functionality of action buttons that enable direct navigation to relevant features.

#### TC-09.01: Start Chat Conversation
**Prerequisite:** User is logged in

| Step | Action | Expected Result |
|------|--------|----------------|
| 1 | Navigate to Chat tab | Chat screen appears |
| 2 | Verify welcome message | Welcome message displays |
| 3 | Check chat interface | Input field and send button visible |

**Actual Result:** Pass / Fail  
**Remarks:** (Add screenshot if failed)

---

#### TC-09.02: Send Message & Receive Response
**Prerequisite:** User is on chat screen

| Step | Action | Expected Result |
|------|--------|----------------|
| 1 | Type a message in input field | Text appears as typed |
| 2 | Tap "Send" button | Message appears in chat |
| 3 | Wait for AI response | **Positive:** AI responds within reasonable time<br>**Negative:** Error message if failed |
| 4 | Verify response format | Response is readable and formatted |

**Actual Result:** Pass / Fail  
**Remarks:** (Add screenshot if failed)

---

#### TC-09.03: Action Buttons Navigation
**Prerequisite:** AI response includes action buttons

| Step | Action | Expected Result |
|------|--------|----------------|
| 1 | Receive AI response with action buttons | Action buttons appear below response |
| 2 | Tap an action button | **Positive:** Navigates to correct screen<br>**Negative:** Error if navigation fails |
| 3 | Verify correct screen opens | Intended feature screen appears |

**Actual Result:** Pass / Fail  
**Remarks:** (Add screenshot if failed)

---

### MODULE 10: POST-LOSS CARE

Post-loss care features provide essential guidance and support during challenging times. The checklist system helps users and their families navigate necessary steps, while support resources offer additional assistance. Testing should verify that checklist items are comprehensive and clear, progress tracking works correctly, and all support resources are easily accessible.

#### TC-10.01: View Checklist
**Prerequisite:** User is logged in

| Step | Action | Expected Result |
|------|--------|----------------|
| 1 | Navigate to Checklist screen | Checklist appears |
| 2 | Verify checklist items display | All items shown correctly |
| 3 | Check item descriptions | Items are clear and understandable |

**Actual Result:** Pass / Fail  
**Remarks:** (Add screenshot if failed)

---

#### TC-10.02: Mark Checklist Items
**Prerequisite:** Checklist is visible

| Step | Action | Expected Result |
|------|--------|----------------|
| 1 | Tap checkbox on a checklist item | Item marked as complete |
| 2 | Verify progress updates | Progress indicator updates |
| 3 | Close and reopen app | Checklist state persists |

**Actual Result:** Pass / Fail  
**Remarks:** (Add screenshot if failed)

---

### MODULE 11: SETTINGS

The settings module encompasses account management, profile customization, theme preferences, subscription management, and security features. Users rely on these features to personalize their experience and maintain their account. Testing should verify that all settings persist correctly, theme changes apply immediately, and account management functions operate securely.

#### TC-11.01: Edit Profile
**Prerequisite:** User is logged in

| Step | Action | Expected Result |
|------|--------|----------------|
| 1 | Navigate to Settings | Settings screen appears |
| 2 | Tap "Edit Profile" | Profile edit form opens |
| 3 | Modify profile information | Changes are saved in form |
| 4 | Tap "Save" | **Positive:** Profile updated successfully<br>**Negative:** Validation errors if invalid |
| 5 | Verify changes | Updated profile displays correctly |

**Actual Result:** Pass / Fail  
**Remarks:** (Add screenshot if failed)

---

#### TC-11.02: Change Theme (Light/Dark)
**Prerequisite:** User is in Settings

| Step | Action | Expected Result |
|------|--------|----------------|
| 1 | Navigate to Settings | Settings screen appears |
| 2 | Locate theme toggle | Theme option visible |
| 3 | Toggle between light/dark mode | **Positive:** Theme changes immediately<br>**Negative:** Theme doesn't change |
| 4 | Verify theme applied | All screens reflect new theme |

**Actual Result:** Pass / Fail  
**Remarks:** (Add screenshot if failed)

---

#### TC-11.03: View Billing/Subscription
**Prerequisite:** User is in Settings

| Step | Action | Expected Result |
|------|--------|----------------|
| 1 | Navigate to Settings | Settings screen appears |
| 2 | Tap "Billing" or "Subscription" | Billing screen appears |
| 3 | Verify subscription status | Current plan/status displays correctly |
| 4 | Check payment history | Payment history visible (if any) |

**Actual Result:** Pass / Fail  
**Remarks:** (Add screenshot if failed)

---

#### TC-11.04: Logout
**Prerequisite:** User is logged in

| Step | Action | Expected Result |
|------|--------|----------------|
| 1 | Navigate to Settings | Settings screen appears |
| 2 | Tap "Logout" button | Confirmation dialog appears |
| 3 | Confirm logout | **Positive:** User logged out, returns to login screen<br>**Negative:** Error if logout fails |
| 4 | Verify login screen | Login screen displays correctly |

**Actual Result:** Pass / Fail  
**Remarks:** (Add screenshot if failed)

---

## TEST SUMMARY

After completing all test cases, please fill in the summary table below with the results for each module. This overview helps identify areas requiring attention and provides a clear picture of overall testing progress and application quality.

| Module | Total Test Cases | Passed | Failed | KIV |
|--------|-----------------|--------|--------|-----|
| Authentication | 5 | | | |
| Home & Navigation | 3 | | | |
| Trust Fund | 5 | | | |
| Hibah | 3 | | | |
| Will | 2 | | | |
| Assets | 4 | | | |
| Family Members | 3 | | | |
| Executors | 3 | | | |
| AI Chat | 3 | | | |
| Post-Loss Care | 2 | | | |
| Settings | 4 | | | |
| **TOTAL** | **37** | | | |

---

## GENERAL REMARKS

Please use this space to provide overall feedback, suggestions, or observations that extend beyond individual test cases. This may include general comments about app performance, user experience, design consistency, or recommendations for future improvements.

(Use this section to add any overall comments, suggestions, or issues not covered in individual test cases)

---

**End of Test Script**
