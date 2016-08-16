/// <reference path="../../definitions/vsts-task-lib.d.ts" />

import os = require('os');
import path = require('path');
import tl = require('vsts-task-lib/task');
import tr = require('vsts-task-lib/toolrunner');

tl.setResourcePath(path.join(__dirname, 'task.json'));

// content is a folder contain artifacts needs to publish.
let pathtoPublish: string = tl.getPathInput('PathtoPublish', true, true);
let artifactName: string = tl.getInput('ArtifactName', true);
let artifactType: string = tl.getInput('ArtifactType', true);

artifactType = artifactType.toLowerCase();

try {
    let data = {
        artifacttype: artifactType,
        artifactname: artifactName
    };

    // upload or copy
    if (artifactType === "container") {
        data["containerfolder"] = artifactName;

        // add localpath to ##vso command's properties for back compat of old Xplat agent
        data["localpath"] = pathtoPublish;
        tl.command("artifact.upload", data, pathtoPublish);
    }
    else if (artifactType === "filepath") {
        let targetPath: string = tl.getInput('TargetPath', true);
        let artifactPath: string = path.join(targetPath, artifactName);
        tl.mkdirP(artifactPath);

        if (os.platform() == 'win32') {
            // create the artifact. at this point, mkdirP already succeeded so the path is good.
            // the artifact should get cleaned up during retention even if the copy fails in the
            // middle
            tl.command("artifact.associate", data, targetPath);

            // copy the files
            let robocopy: tr.ToolRunner = new tr.ToolRunner('robocopy');
            robocopy.arg('/E'); // copy subdirectories, including Empty ones.
            robocopy.arg('/NP'); // No Progress - don't display percentage copied.
            robocopy.arg('/R:3'); // number of Retries on failed copies
            robocopy.arg(pathtoPublish); // source
            robocopy.arg(artifactPath); // destination
            robocopy.arg('*'); // file
            let execOptions: tr.IExecOptions = { ignoreReturnCode: true };
            let result: tr.IExecResult = robocopy.execSync(execOptions);
            if (result.code >= 8) {
                tl.setResult(tl.TaskResult.Failed, tl.loc('RobocopyFailed', result.code));
            }
        }
        else {
            // log if the path does not look like a UNC path (artifact creation will fail)
            if (!artifactPath.startsWith('\\\\') || artifactPath.length < 3) {
                console.log(tl.loc('UncPathRequired'));
            }

            // create the artifact
            data['artifactlocation'] = targetPath; // artifactlocation for back compat with old xplat agent
            tl.command("artifact.associate", data, targetPath);

            console.log(tl.loc('SkippingCopy')); // add fwlink to message
        }
    }
}
catch (err) {
    tl.setResult(tl.TaskResult.Failed, tl.loc('PublishBuildArtifactsFailed', err.message));
}