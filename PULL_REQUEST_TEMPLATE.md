### Requirements

- Filling out the template is required. Any pull request that does not include enough information to be reviewed in a timely manner may be closed at the maintainers' discretion;
- Review the [contributing guidelines](https://github.com/Ensembl/ensembl/blob/master/CONTRIBUTING.md#why-could-my-pull-request-be-rejected) for this repository; remember in particular:
    - do not modify code without testing for regression
    - provide simple unit tests to test the changes
    - the PR must not fail unit testing
    - if you're adding/updating documentation of an endpoint, make sure you add/update the necessary parameters to the (template) configuration files in the ensembl-rest_private repo

### Description

_Using one or more sentences, describe in detail the proposed changes._

### Use case

_Describe the problem. Please provide an example representing the motivation behind the need for having these changes in place._

### Benefits

_If applicable, describe the advantages the changes will have._

### Possible Drawbacks

_If applicable, describe any possible undesirable consequence of the changes._

### Testing

note to submitters and reviewers: documentation-only changes may reflect
changes in other repos that can result in new or different output from
REST endpoints. In turn, these may require new tests or changes to existing tests.

_Have you added/modified unit tests to test the changes?_

_If so, do the tests pass/fail?_

_Have you run the entire test suite and no regression was detected?_

### Changelog

_Are you changing the functionality of an endpoint? If so, please give a one line summary for the public facing changelog._

eg. [/xenobiology/orthologs] Added the ability to look up orthologs and paralogs from klingons and andorians
