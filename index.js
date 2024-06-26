var fs = require('fs');
var async = require('async');
var aws = require('aws-sdk');
var sqs = new aws.SQS({apiVersion: '2012-11-05'});
var ecs = new aws.ECS({apiVersion: '2014-11-13'});

// Check if the given key suffix matches a suffix in the whitelist.
// Return true if it matches, false otherwise.
exports.checkS3SuffixWhitelist = function(key, whitelist) {
	if (!whitelist) {
		return true;
	}

	if (typeof whitelist == 'string') {
		return key.match(whitelist + '$')
	}

	if (Object.prototype.toString.call(whitelist) === '[object Array]') {
		for(var i = 0; i < whitelist.length; i++) {
			if(key.match(whitelist[i] + '$')) {
				return true;
			}
		}

		return false;
	}

	console.log(
		'Unsupported whitelist type (' + Object.prototype.toString.call(whitelist) +
		') for: ' + JSON.stringify(whitelist)
	);

	return false;
};

exports.handler = function(event, context) {
	console.log('Received event:');
	console.log(JSON.stringify(event, null, '  '));

	var config = JSON.parse(fs.readFileSync('config.json', 'utf8'));
	if (!config.hasOwnProperty('s3_key_suffix_whitelist')) {
		config.s3_key_suffix_whitelist = false;
	}

	console.log('Config: ' + JSON.stringify(config));

	var key = event.Records[0].s3.object.key;
	if (!exports.checkS3SuffixWhitelist(key, config.s3_key_suffix_whitelist)) {
		context.fail('Suffix for key: ' + key + ' is not in the whitelist')
	}

	// We can now go on. Put the S3 URL into SQS and start an ECS task to process it.
	async.waterfall([
			function (next) {
				var params = {
					MessageBody: JSON.stringify(event),
					QueueUrl: config.queue
				};

				sqs.sendMessage(params, function (err, data) {
					if (err) {
						console.warn('Error while sending message: ' + err);
					}
					else {
						console.info('Message sent, ID: ' + data.MessageId);
					}
					next(err);
				});
			},
			function (next) {
				// Starts an ECS task to work through the feeds.
				var params = {
					taskDefinition: config.task,
					count: 1
				};

				ecs.runTask(params, function (err, data) {
					if (err) {
						console.warn('error: ', "Error while starting task: " + err);
					}
					else {
						console.info('Task ' + config.task + ' started: ' + JSON.stringify(data.tasks))
					}
					next(err);
				});
			}
		], function (err) {
			if (err) {
				context.fail('An error has occurred: ' + err);
			}
			else {
				context.succeed('Successfully processed Amazon S3 URL.');
			}
		}
	);
};
