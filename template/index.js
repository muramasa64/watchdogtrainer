var AWS = require('aws-sdk');

exports.handler = function(event, context) {
    event_json = JSON.stringify(event);
    console.log(event_json);

    event_names = {
        "AuthorizeSecurityGroupIngress": "Inbound追加",
        "RevokeSecurityGroupIngress": "Inbound削除",
        "AuthorizeSecurityGroupEgress": "Outbound追加",
        "RevokeSecurityGroupEgress": "Outbound削除"
    };

    var ec2 = new AWS.EC2({region: '<%= region %>'});
    var param = {GroupIds: [event.detail.requestParameters.groupId]};
    ec2.describeSecurityGroups(param, function(err, data) {
        if (err) {
            console.log(err, err.stack);
        }
        else {
            console.log(JSON.stringify(data));

            var tag_name = '';
            for(var i = 0; i < data.SecurityGroups[0].Tags.length; i++) {
                if(data.SecurityGroups[0].Tags[i].Key === 'Name') {
                    tag_name = data.SecurityGroups[0].Tags[i].Value;
                }
            }

            var message =
                "セキュリティグループのルールが変更されました。\n\n" +
                "時刻: " + event.detail.eventTime + "\n" +
                "ユーザーARN: " + event.detail.userIdentity.arn + "\n" +
                "ソースIPアドレス: " + event.detail.sourceIPAddress + "\n" +
                "対象Security Group: " + event.detail.requestParameters.groupId +
                " (Name: " + data.SecurityGroups[0].GroupName + ", tag:Name: " + tag_name + ")\n" +
                "変更内容: " + event_names[event.detail.eventName] + "\n";

            ip_perms = event.detail.requestParameters.ipPermissions.items;
            for (var j = 0; j < ip_perms.length; j++) {
                message +=
                    "    プロトコル: " + ip_perms[j].ipProtocol + "\n" +
                    "    ポート: " + ip_perms[j].fromPort + " - " + ip_perms[j].toPort + "\n" +
                    "    IPアドレス: " + ip_perms[j].ipRanges.items.map(function(x) {return x.cidrIp}).join(", ") + "\n";
            }

            var params = {
                Message: message,
                Subject: 'Security Group Rule Changed at ' + event.detail.eventTime,
                TopicArn: 'arn:aws:sns:<%= region %>:<%= aws_account_number %>:<%= name %>'
            };

            var sns = new AWS.SNS({region: '<%= region %>'});
            sns.publish(params, function(err, data) {
                if (err) {
                    console.log(err, err.stack);
                }
                else {
                    console.log(data);
                    context.succeed('Ready');
                }
            });
        }
    });
};
