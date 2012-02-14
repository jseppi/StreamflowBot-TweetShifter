## Twitter stream using JRuby & MongoDB

Sample application how to monitor twitter keywords/users using JRuby and twitter4j.

Data are saved into MongoDB database using Mongoid library.

Web frontend using Sinatra, jQuery, HighCharts and Bootstrap.

## How to

Copy config/environment.example to config/development.rb and adjust required parameters.

Run application using rackup.

## Deploying

### OpenShift

Convert application using warbler into war file. Create account at

        https://openshift.redhat.com

then deploy application as regular java web application.

** You will need to add MongoDB into your instance **

## Coming soon

* Clean up all the mess
* Android push notifications
* More complex dashboard
* Archive browsing

## Deployment

Demo deployment monitoring @openshift user and 'openshift' keyword.

[http://demos-mjelen.rhcloud.com/oshift-twitter](http://demos-mjelen.rhcloud.com/oshift-twitter/)