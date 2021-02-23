![ABAP 7.00+](https://img.shields.io/badge/ABAP-7.00%2B-brightgreen)

**ATTENTION**: The API is still under development, and subject to change.

## `ABAP Concurrency API`

API for parallel programming based on the SPTA Framework.

## What it is?

Utility classes useful in concurrent programming.

## What is this for?

Implementing parallel computing in ABAP typically involves the following steps:

1. Creating an RFC function module
2. **Implementation of business logic** inside it
3. Asynchronous calling RFC function module in a loop
4. Waiting for execution and **getting results of work**

If you look at the resulting list, you will notice that, by and large, we are only interested in steps **`2`** and **`4`**.
Everything else is routine work that takes time every time and, potentially, can be a source of errors.

To avoid generating an RFC function module every time you need to do parallel processing, you can use the SPTA Framework provided by the vendor.   

The SPTA Framework is a good tool, but its interface leaves a lot to be desired. Because of this, the developer has to make a lot of effort to implement the parallelization process itself.

In addition, writing clean code using the SPA Framework directly is also not the easiest task. You need to be a real ninja to avoid using global variables. After all, the code can be confusing and difficult to maintain.

The `ABAP Concurrency API` avoids these problems. With it, you can allow yourself to think more abstractly.
You don't need to focus on parallelization. Instead, you can spend more time on the business logic of your application.

## Installation

There are two easy ways to install the ABAP Concurrency API:

1. [abapGit](http://www.abapgit.org).
2. [SAPlink](https://gist.github.com/victorizbitskiy/bcbd9ea7ac4ef7a06e58c01b06b4cce0)

## Using

Let's consider a simple task:  

*You need to find the squares of numbers from **`1`** to **`10`***.

The square of each of the numbers will be found in a separate task/process.  
The example is detached from the real world, but it is enough to understand how to work with the API.

First, let's create the 3 classes we need: *Context*, *Task* and *Result*.

1. **lcl_contex**, an object of this class encapsulates the task parameters.
   The use of this class is optional. You can do without it by passing the task parameters directly to its constructor.
   However, in my opinion, it is preferable to use a separate class.

```abap
CLASS lcl_context DEFINITION FINAL.
  PUBLIC SECTION.
    INTERFACES: if_serializable_object.

    TYPES: BEGIN OF ty_params,
             param TYPE i,
           END OF ty_params.

    METHODS: constructor IMPORTING is_params TYPE ty_params,
             get RETURNING VALUE(rs_params) TYPE ty_params.

  PRIVATE SECTION.
    DATA: ms_params TYPE ty_params.
ENDCLASS.

CLASS lcl_context IMPLEMENTATION.
  METHOD constructor.
    ms_params = is_params.
  ENDMETHOD.

  METHOD get.
    rs_params = ms_params.
  ENDMETHOD.
ENDCLASS.
```

2. **lcl_task**, describes an object *Task*. Contains business logic (in our case, raising a number to the power of 2).
   Note that the **lcl_task** class inherits from the **zcl_capi_abstract_task** class and overrides the **zif_capi_callable~call** method.

```abap
CLASS lcl_task DEFINITION INHERITING FROM zcl_capi_abstract_task FINAL.
  PUBLIC SECTION.

    METHODS: constructor IMPORTING io_context TYPE REF TO lcl_context,
             zif_capi_callable~call REDEFINITION.

  PRIVATE SECTION.
    DATA: mo_context TYPE REF TO lcl_context.
    DATA: mv_res TYPE i.
ENDCLASS.

CLASS lcl_task IMPLEMENTATION.
  METHOD constructor.
    super->constructor( ).
    mo_context = io_context.
  ENDMETHOD.

  METHOD zif_capi_callable~call.
    DATA: ls_params TYPE lcl_context=>ty_params.

    ls_params = mo_context->get( ).
    mv_res = ls_params-param ** 2.

    CREATE OBJECT ro_result
      TYPE
      lcl_result
      EXPORTING
        iv_param  = ls_params-param
        iv_result = mv_res.
  ENDMETHOD.
ENDCLASS.
```

3. **lcl_result** describes *the result* of the task.
   This class must implement the **if_serializable_object** interface. Otherwise, you can describe it in any way you want.

```abap
CLASS lcl_result DEFINITION FINAL.
  PUBLIC SECTION.
    INTERFACES: if_serializable_object.

    METHODS: constructor IMPORTING iv_param  TYPE i
                                   iv_result TYPE i,
             get RETURNING VALUE(rv_result) TYPE string.

  PRIVATE SECTION.
    DATA: mv_param TYPE i.
    DATA: mv_result TYPE i.
ENDCLASS.

CLASS lcl_result IMPLEMENTATION.
  METHOD constructor.
    mv_param = iv_param.
    mv_result = iv_result.
  ENDMETHOD.

  METHOD get.
    DATA: lv_param  TYPE string,
          lv_result TYPE string.

    lv_param = mv_param.
    lv_result = mv_result.

    CONDENSE lv_param.
    CONDENSE lv_result.
    CONCATENATE lv_param ` -> ` lv_result INTO rv_result.
  ENDMETHOD.
ENDCLASS.
```

**Attention:**  
Objects of the **local_task** and **lcl_result** classes are serialized/deserialized at runtime, so avoid using static attributes.
Static attributes belong to the class, not the object. Their contents will be lost after serialization/deserialization.

So, the objects *Context*, *Task*, and *Result* are described.
Now, let's have a look at example:

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

1. First, create *Tasks collection* **lo_tasks**
2. Next, create a *Task* **lo_task** and add it to the *Tasks collection* **lo_tasks**
3. Create a message handler **lo_message_handler**
4. Now we come to the most important part of the API f- the concept of an `executor_service`. The executor asynchronously executes the tasks passed to it.  
   Create an object **lo_executor** of class **zcl_capi_executor_service**. The class constructor has 4 parameters:

| Parameter name              | Description                                                  |
| :-------------------------- | :----------------------------------------------------------- |
| iv_server_group             | server group (tcode: RZ12)                                   |
| iv_max_no_of_tasks          | maximum number of concurrent tasks                           |
| iv_no_resubmission_on_error | flag "**true**" - don't restart the task in case of an error |
| io_capi_message_handler     | an object that will contain error messages (if they occurred) |

  The **lo_executor** object has only one interface method **invoke_all ()**, which takes as input a **collection of tasks** and returns a **collection of results** **lo_results** (the approach was taken from ***java.util.concurrent.***).

5. The *Collection of results* **lo_results** has an iterator, using which we easily get the **lo_result** and call the **get() **method from them.

As a result, we did't have to create an RFC functional module, describe the parallelization process, etc.
All we did was describe what the *Task* and *Result* are.

**Result of execution:**

![result](https://github.com/victorizbitskiy/zconcurrency_api/blob/main/docs/img/result.png)

An example of using the `ABAP Concurrency API` can be found in the **ZCONCURRENCY_API_EXAMPLE** report.

# UML Class Diagram

![UML Class Diagram](https://github.com/victorizbitskiy/zconcurrency_api/blob/main/docs/img/UML%20Class%20Diagram.png)

# License

[Unlicense License](https://github.com/victorizbitskiy/zconcurrency_api/blob/main/LICENSE)
