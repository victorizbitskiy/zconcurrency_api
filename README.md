![ABAP 7.00+](https://img.shields.io/badge/ABAP-7.00%2B-brightgreen)

# `ABAP Concurrency API`
Concurrency API based on SPTA Framework

# What is it
Classes useful in concurrent programming. This package includes a few small classes that provide useful functionality and are otherwise tedious or difficult to implement.

# Installation
There are currently 2 ways to install `ABAP Concurrency API`:

1. [abapGit](http://www.abapgit.org).
2. [SAPlink](https://gist.github.com/victorizbitskiy/bcbd9ea7ac4ef7a06e58c01b06b4cce0)

# Usage
An example of using `ABAP Concurrency API` can be viewed in the report **ZCONCURRENCY_API_EXAMPLE**.

In short, it looks like this (Abap 7.4):

```abap
    DATA: lo_result TYPE REF TO lcl_result.

*   Create collection of tasks
    DATA(lo_tasks) = NEW zcl_capi_collection( ).

    DO 10 TIMES.
      DATA(lo_task) = NEW lcl_task(
                                    NEW lcl_context(
                                                     VALUE lcl_context=>ty_params( param = sy-index )
                                                     )
                                    ).
      lo_tasks->zif_capi_collection~add( lo_task ).
    ENDDO.

    DATA(lo_message_handler) = NEW zcl_capi_message_handler( ).
    DATA(lo_executor) = NEW zcl_capi_executor_service( iv_server_group             = 'parallel_generators'
                                                       iv_max_no_of_tasks          = 5
                                                       iv_no_resubmission_on_error = abap_false
                                                       io_capi_message_handler     = lo_message_handler ).
                                                       
    DATA(lo_results) = lo_executor->zif_capi_executor_service~invoke_all( lo_tasks ).
    DATA(lo_results_iterator) = lo_results->get_iterator( ).

    WHILE lo_results_iterator->has_next( ).
      lo_result ?= lo_results_iterator->next( ).
      DATA(lv_result) = lo_result->get( ).
      WRITE: / lv_result.
    ENDWHILE.

```
It's easy, isn't it?

# UML Class Diagram
![UML Class Diagram](https://github.com/victorizbitskiy/zconcurrency_api/blob/main/docs/img/UML%20Class%20Diagram.png)

# License
[Unlicense License](https://github.com/victorizbitskiy/zconcurrency_api/blob/main/LICENSE)
