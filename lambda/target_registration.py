import json
import os

import boto3

elbv2 = boto3.client("elbv2")
ec2 = boto3.client("ec2")
asg = boto3.client("autoscaling")

TARGET_GROUP_ARN = os.environ["TARGET_GROUP_ARN"]
TARGET_PORT = int(os.environ.get("TARGET_PORT", "80"))
DEV_INSTANCE_NAMES = set(os.environ.get("DEV_INSTANCE_NAMES", "").split(","))


def ip_and_tags(instance_id):
    response = ec2.describe_instances(InstanceIds=[instance_id])
    for reservation in response["Reservations"]:
        for instance in reservation["Instances"]:
            primary_ip = instance.get("PrivateIpAddress")
            tags = {tag["Key"]: tag["Value"] for tag in instance.get("Tags", [])}
            return primary_ip, tags
    return None, {}


def target_for(instance_id):
    ip, tags = ip_and_tags(instance_id)
    if not ip:
        return None, tags
    return {"Id": ip, "Port": TARGET_PORT, "AvailabilityZone": "all"}, tags


def register(instance_id):
    target, tags = target_for(instance_id)
    if target:
        elbv2.register_targets(TargetGroupArn=TARGET_GROUP_ARN, Targets=[target])
    return target, tags


def deregister(instance_id):
    target, tags = target_for(instance_id)
    if target:
        elbv2.deregister_targets(TargetGroupArn=TARGET_GROUP_ARN, Targets=[target])
    return target, tags


def handle_sns_lifecycle(event):
    message = event["Records"][0]["Sns"]["Message"]
    data = json.loads(message)
    lifecycle = data["LifecycleTransition"].split(":")[-1]
    instance_id = data["EC2InstanceId"]
    hook_name = data["LifecycleHookName"]
    asg_name = data["AutoScalingGroupName"]
    token = data["LifecycleActionToken"]

    target = None
    if lifecycle == "EC2_INSTANCE_LAUNCHING":
        target, _ = register(instance_id)
    elif lifecycle == "EC2_INSTANCE_TERMINATING":
        target, _ = deregister(instance_id)

    asg.complete_lifecycle_action(
        LifecycleHookName=hook_name,
        AutoScalingGroupName=asg_name,
        LifecycleActionToken=token,
        LifecycleActionResult="CONTINUE",
    )
    return {"status": "ok", "source": "asg", "instance": instance_id, "target": target}


def handle_ec2_state_change(event):
    instance_id = event["detail"]["instance-id"]
    state = event["detail"]["state"]
    target, tags = target_for(instance_id)
    name = tags.get("Name", "")
    if name not in DEV_INSTANCE_NAMES:
        return {"status": "ignored", "reason": "not-dev-target", "instance": instance_id}

    if state == "running" and target:
        elbv2.register_targets(TargetGroupArn=TARGET_GROUP_ARN, Targets=[target])
    elif state in ["stopping", "stopped", "shutting-down", "terminated"] and target:
        elbv2.deregister_targets(TargetGroupArn=TARGET_GROUP_ARN, Targets=[target])
    return {"status": "ok", "source": "eventbridge", "state": state, "instance": instance_id, "target": target}


def handler(event, context):
    print(json.dumps(event))
    if "Records" in event and event["Records"][0].get("EventSource") == "aws:sns":
        return handle_sns_lifecycle(event)
    if event.get("source") == "aws.ec2":
        return handle_ec2_state_change(event)
    return {"status": "ignored", "event": event}
