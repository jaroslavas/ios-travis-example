#!/bin/sh
":" //# http://sambal.org/?p=1014 ; exec /usr/bin/env node --harmony "$0" "$@"
const request = require('request');
const _ = require('lodash');
const path = require('path');
const fs = require('fs');
const Rx = require('rxjs');
const xml2js = require('xml2js');
const mkdirp = require('mkdirp');

const CONCURRENCY = 3;

const agent = function agent(appBasePath) {
    "use strict";

    let settings = {};

    const generatorFunctions = {
        generateFlavorScreengrab: function (params) {
            return `app_package_name '${settings['DEPLOY_PACKAGE_NAME']}'
tests_package_name '${settings['DEPLOY_PACKAGE_NAME']}.test'
# prd_dk_Takeout_tst_0.1.0_debug_.apk
app_apk_path 'app/build/outputs/apk/app-${settings['DEPLOY_FLAVOR']}${settings['DEPLOY_APPLICATION_NAME']}_tst_${settings['DEPLOY_VERSION']}_debug_.apk'
# app-prd_dk_-debug-androidTest-unaligned.apk
tests_apk_path 'app/build/outputs/apk/app-${settings['DEPLOY_FLAVOR']}-debug-androidTest-unaligned.apk'
locales ['en-US']
clear_previous_screenshots true
test_instrumentation_runner 'android.support.test.runner.AndroidJUnitRunner'
output_directory '/sdcard/screenShoots'
`;
        },
        generateFastLaneConfig: function (params) {
            return `
json_key_file "${settings['DEPLOY_GOOGLE_PK']}" # Path to the json secret file - Follow https://github.com/fastlane/supply#setup to get one
package_name "${settings['DEPLOY_PACKAGE_NAME']}" # e.g. com.krausefx.app
`;
        },
        generateMetaFile: function (params) {
            return params.text;
        }
    };

    function handleException(err) {
        "use strict";
        console.log('FATAL Application error', err.stack);
        process.exit(1);
    }

    function validateDeploymentSettings() {
        "use strict";
        let requiredVars = [
            'DEPLOY_MESSAGE',
            'DEPLOY_VERSION',
            'DEPLOY_APPSETTINGSURL'
        ];
        if (process.argv.length < 3) {
            let deploymentCheck = process.env.DEPLOY_SETTINGS;
            if (!deploymentCheck) {
                throw new Error('Env is not set for deployment');
            }
            let settingKeys = deploymentCheck.split(',');
            settingKeys.forEach(key => {
                settings[key] = process.env[key];
                if (settings[key] == null) {
                    throw new Error('Variable value assertion failed');
                }
            });
        } else {
            console.log('Using json params file');
            settings = JSON.parse(fs.readFileSync(path.resolve(process.argv[2])));
        }

        console.log('Deployment Settings set', settings);
        requiredVars.forEach(key => {
            if (!settings.hasOwnProperty(key)) {
                throw new Error('Required variable is missing - ' + key);
            }
        });
    }

    function downloadFile(url, fileName) {
        return new Rx.Observable((o) => {
            "use strict";
            request
                .get(url, {}, (err, response) => {
                    if (err) {
                        console.log('HTTP - Downloading file has failed', url);
                        return o.error(err);
                    }
                    if (response.statusCode < 200 || response.statusCode >= 400) {
                        console.log('HTTP - Downloading file has failed', url);
                        return o.error(err);
                    }
                    o.next(fileName);
                    o.complete();
                })
                .pipe(fs.createWriteStream(fileName));
        })
    }

    function downloadResourcesTask(settings$) {
        return settings$
            .flatMap(s => Rx.Observable.from(s.resources))
            .filter(resMeta => resMeta.variants.indexOf(settings['DEPLOY_VARIANT']) !== -1)
            .flatMap(resMeta => Rx.Observable.from(resMeta.files.map(resource => ({
                url: resource.url,
                path: path.join(appBasePath, resource.path)
            }))))
            .mergeMap(res => downloadFile(res.url, res.path), (res, file) => file, CONCURRENCY)
            .map(file => ({description: 'File Download', value: file}))
            ;
    }

    function getAppSettings() {
        "use strict";
        let url = settings['DEPLOY_APPSETTINGSURL'];
        let token = settings['DEPLOY_WSAUTHTOKEN'];
        let user = settings['DEPLOY_WSAUTHBASICUSER'];
        let password = settings['DEPLOY_WSAUTHBASICPASSWORD'];

        return Rx.Observable.create(o => {
            request(url, {
                headers: {
                    'X-AUTH-TOKEN': token
                },
                auth: {
                    'user': user,
                    'pass': password
                },
                json: true
            }, (err, result) => {
                if (err) {
                    console.log('HTTP Request - Failed');
                    return o.error(err);
                }
                if (result.statusCode !== 200) {
                    return o.error(new Error('HTTP Request - Invalid status code ' + result.statusCode));
                }
                o.next(result.body);
                o.complete();
            })
        }).share()
    }

    function writeToFile(path, data) {
        "use strict";
        return Rx.Observable.create(o => {
            "use strict";
            fs.writeFile(path, data, {}, (err) => {
                if (err) {
                    return o.error(err);
                }
                o.next(path);
                o.complete();
            })
        });
    }

    function processXmlConfiguration(path, properties) {
        return Rx.Observable.create(o => {
            "use strict";
            let parser = new xml2js.Parser();
            let builder = new xml2js.Builder();
            if (fs.existsSync(path)) {
                fs.readFile(path, {}, (err, res) => {
                    "use strict";
                    if (err) {
                        return o.error(err);
                    }
                    parser.parseString(res, function (err, defaultXml) {
                        if (err) {
                            return o.error(err);
                        }
                        console.log('Merging xml file', path, defaultXml);
                        o.next(builder.buildObject(_.defaultsDeep({}, properties, defaultXml)));
                        parser.reset();
                        o.complete();
                    });
                });
            } else {
                console.log('Creating new XML file', path, properties);
                o.next(builder.buildObject(properties));
                o.complete();
            }
        })
    }

    function setParametersTask(settings$) {
        "use strict";
        let configs$ = settings$
                .flatMap(s => Rx.Observable.from(s.generateCfgs))
                .filter(cfgMeta => cfgMeta.variants.indexOf(settings['DEPLOY_VARIANT']) !== -1)
                .map(cfgMeta => {
                    cfgMeta.path = path.join(appBasePath, cfgMeta.path);
                    return cfgMeta;
                })
            ;

        let xmlGenerating = configs$
                .filter(cfgMeta => cfgMeta.type === 'xml')
                .mergeMap(cfgMeta => processXmlConfiguration(cfgMeta.path, cfgMeta.properties),
                    (cfgMeta, data) => ({
                        path: cfgMeta.path,
                        data
                    })
                )
            ;

        return Rx.Observable.merge(xmlGenerating)
            .flatMap(writeMeta => writeToFile(writeMeta.path, writeMeta.data))
            .map(path => ({description: 'Generate config file', value: path}))
            ;
    }

    function generateConfigFilesTask(settings$) {
        "use strict";
        return settings$
                .flatMap(s => Rx.Observable.from(s.generators))
                .filter(cfgMeta => cfgMeta.variants.indexOf(settings['DEPLOY_VARIANT']) !== -1)
                .mergeMap(cfgMeta => {
                    let fn = generatorFunctions[cfgMeta.function];
                    if (typeof fn !== 'function') {
                        throw new Error('Generator function not found');
                    }
                    return Rx.Observable.of(fn(cfgMeta.params));
                }, (cfgMeta, data) => ({
                    path: cfgMeta.path,
                    data
                }))
                .flatMap(writeMeta => {
                    return Rx.Observable.create(o => {
                        mkdirp(path.dirname(writeMeta.path), (err) => {
                            if (err) {
                                return o.error(err);
                            }
                            o.next(writeToFile(writeMeta.path, writeMeta.data));
                            o.complete();
                        });
                    })
                })
                .switch()
                .map(path => ({description: 'Generate configuration file', value: path}))
            ;
    }

    function writeVersionInfoTask(settings$) {
        "use strict";
        let configs$ = settings$
            .flatMap(s => Rx.Observable.from(s.versionInfo))
            .filter(cfgMeta => cfgMeta.variants.indexOf(settings['DEPLOY_VARIANT']) !== -1)
            .map(cfgMeta => {
                cfgMeta.path = path.join(appBasePath, cfgMeta.path);
                return cfgMeta;
            });

        let xmlGenerating = configs$
                .filter(cfgMeta => cfgMeta.type === 'xml')
                .mergeMap(cfgMeta => processXmlConfiguration(cfgMeta.path, {
                    "resources": {
                        "string": [
                            {
                                "_": settings['DEPLOY_PACKAGE_NAME'] || '',
                                "$": {"name": "applicationId"}
                            },
                            {
                                "_": settings['DEPLOY_VERSION'] || '',
                                "$": {"name": "versionName"}
                            }
                        ],
                        "integer": [
                            {"_": settings['DEPLOY_VERSION'].replace(/\./g, '') || '', "$": {"name": "versionCode"}}
                        ]
                    }
                }), (cfgMeta, data) => ({
                    path: cfgMeta.path,
                    data
                }))
            ;

        return Rx.Observable.merge(xmlGenerating)
            .flatMap(writeMeta => writeToFile(writeMeta.path, writeMeta.data))
            .map(path => ({description: 'Generate build xml file', value: path}))
            ;
    }

    this.run = function () {
        process.on('unhandledRejection', handleException);
        let RUNNING = true;

        console.log('Validating deployment env');
        validateDeploymentSettings();

        console.log('Getting settings from ws');
        let settings$ = getAppSettings();

        Rx.Observable
            .merge(
                setParametersTask(settings$),
                downloadResourcesTask(settings$),
                writeVersionInfoTask(settings$),
                generateConfigFilesTask(settings$)
            )
            .subscribe((task) => {
                console.log('Task "%s" (%s) - Done', task.description, task.value);
            }, (err) => handleException(err), () => {
                console.log('Done');
                RUNNING = false;
            })
        ;

        (function wait() {
            if (RUNNING) setTimeout(wait, 1000);
        })();
    };
};

module.exports = agent;
const Agent = agent;

const AgentApp = new Agent(process.cwd());
AgentApp.run();