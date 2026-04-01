# AWS Onboarding — IAM User with Programmatic Access

This guide creates an IAM user with least-privilege access for compute automation (EC2/ECS/Lambda). By the end, you'll have an `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` the skill can use.

---

## Policy Used

The inline policy from `schemas/aws-compute-policy.json` grants:
- **EC2:** describe, run, start, stop, terminate instances; manage security groups and tags
- **ECS:** describe, list, run/stop tasks, update services
- **Lambda:** get, invoke, list, update functions
- Region-locked to `us-east-1` and `us-west-2` by default (edit the condition to change)
- `iam:PassRole` scoped to roles named `agent-automation-*`

---

## Option A: AWS Console

### 1. Create the IAM Policy

1. Sign in to the [IAM console](https://console.aws.amazon.com/iam/)
2. Navigate to **Policies** → **Create policy**
3. Select the **JSON** tab and paste the contents of `schemas/aws-compute-policy.json`
4. Click **Next**, name it `AgentComputeAutomation`
5. Optionally add a description: `Least-privilege compute automation for AI agent skills`
6. Click **Create policy**

### 2. Create the IAM User

1. In IAM, navigate to **Users** → **Create user**
2. Enter a username, e.g. `agent-compute`
3. **Do not** check "Provide user access to the AWS Management Console" (programmatic only)
4. Click **Next**

### 3. Attach the Policy

1. On the "Set permissions" screen, choose **Attach policies directly**
2. Search for `AgentComputeAutomation` and check it
3. Click **Next** → **Create user**

### 4. Create Access Keys

1. Click on the newly created user → **Security credentials** tab
2. Under "Access keys", click **Create access key**
3. Select **Application running outside AWS** → **Next**
4. Click **Create access key**

> ⚠️ **ONE-TIME WARNING:** This is the only time you can download the secret access key. Copy or download the CSV now. If you lose it, you must delete and recreate the key.

5. Save `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` to your credential store

---

## Option B: AWS CLI

```bash
# 1. Create the policy (from repo root)
POLICY_ARN=$(aws iam create-policy \
  --policy-name AgentComputeAutomation \
  --description "Least-privilege compute automation for AI agent skills" \
  --policy-document file://skills/cloud-provisioning/schemas/aws-compute-policy.json \
  --query 'Policy.Arn' --output text)

echo "Policy ARN: $POLICY_ARN"

# 2. Create the IAM user
aws iam create-user --user-name agent-compute

# 3. Attach the policy
aws iam attach-user-policy \
  --user-name agent-compute \
  --policy-arn "$POLICY_ARN"

# 4. Create access key
# ⚠️ Save the output immediately — the secret is never shown again
aws iam create-access-key --user-name agent-compute
```

The output will look like:
```json
{
  "AccessKey": {
    "AccessKeyId": "AKIA...",
    "SecretAccessKey": "abc123...",
    "Status": "Active"
  }
}
```

---

## Verification

Once credentials are in place (e.g., via `aws configure` or environment variables):

```bash
# Should return a list of EC2 instances (or empty list — both are success)
aws ec2 describe-instances --region us-east-1 --query 'Reservations[].Instances[].InstanceId'

# Verify identity
aws sts get-caller-identity
```

Expected output for `get-caller-identity`:
```json
{
    "UserId": "AIDA...",
    "Account": "123456789012",
    "Arn": "arn:aws:iam::123456789012:user/agent-compute"
}
```

---

## Gotchas

### IAM Propagation Delay
AWS IAM changes can take **up to 60 seconds** to propagate globally. If you immediately run the verification command and get an `AccessDenied` error, wait a minute and retry.

### Forgetting to Download the Secret Key
The `SecretAccessKey` is only shown once — at creation time. If you close the window before saving it, you must:
1. Go to the user's **Security credentials** tab
2. Deactivate and delete the old key
3. Create a new key

There is no way to retrieve a lost secret key.

### Policy Too Restrictive
The default policy restricts actions to `us-east-1` and `us-west-2` via the `aws:RequestedRegion` condition. If you need other regions, edit the policy's `Condition` block:

```json
"Condition": {
  "StringEquals": {
    "aws:RequestedRegion": ["us-east-1", "us-west-2", "eu-west-1"]
  }
}
```

Or remove the condition entirely to allow all regions (less secure).

### PassRole Scope
The `iam:PassRole` permission is scoped to roles matching `arn:aws:iam::*:role/agent-automation-*`. If your ECS tasks or Lambda functions use execution roles with different names, add those ARNs to the `Resource` list in the `IAMPassRole` statement.

### Least-Privilege Reminder
This policy uses `"Resource": "*"` for most actions. For production use, scope resources to specific VPCs, subnets, or resource ARNs where possible.
