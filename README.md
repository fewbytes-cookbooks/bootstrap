Description
===========
Bootstarp logic for new instances, autoconfigure chef-client and friends


Requirements
============

Attributes
==========

Usage
=====
With CloudFormation, use the folowing in `Mappings`:

    "Mappings": {
        "UserData": {
            "CloudInit": {
            "BaseInclude": "http://public.fewbytes.com/bootstrap/latest/ubuntu-chef-base.yaml"
            }
        },
        "Config": {
            "Chef": {
                "serverURL": "https://chef.server.url.com:444",
                "validationCert": "-----BEGIN RSA PRIVATE KEY-----\n-----END RSA PRIVATE KEY-----"
            },
            "Misc": {
                "domain": "fewbytes.info"
            }
        }
    }

Then in your Instance resource (or AutoScalingLaunchConfig) use the following:

        "UserData": {"Fn::Base64": {"Fn::Join": ["\n", [
          "#include-once",
          {"Fn::FindInMap": ["UserData", "CloudInit", "BaseInclude"]}
          ] ]
        }},

And in metadata use:

      "Metadata": {
        "chef": {
          "role": "storm_nimbus",
          "run_list": ["role[storm_nimbus]", "recipe[cloudformation::signal]"],
          "serverURL": {"Fn::FindInMap":["Config", "Chef", "serverURL"]},
          "validationCert": {"Fn::FindInMap":["Config", "Chef", "validationCert"]},
          "environment": {"Ref": "Environment"}
        },
        "generic": {
          "domain": {"Fn::FindInMap": ["Config", "Misc", "domain"]}
        }
      },

*Note*: For AutoscalingGroups put the metadata in the AutoScalingGroup resource and not the AutoScalingLaunchConfig. UserData goes in LaunchConfig, Metadata in AutoScalingGroup.
