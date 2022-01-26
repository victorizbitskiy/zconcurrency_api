<img src="https://github.com/victorizbitskiy/zconcurrency_api/blob/main/logo/octo.svg" height="100px"/>\

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://github.com/victorizbitskiy/zconcurrency_api/blob/main/LICENSE)
![ABAP 7.00+](https://img.shields.io/badge/ABAP-7.00%2B-brightgreen)
[![Code Statistics](https://img.shields.io/badge/CodeStatistics-abaplint-blue)](https://abaplint.app/stats/victorizbitskiy/zconcurrency_api)

**ATTENTION**: The API is still under development and subject to change.

Translations:
- [:ru: На русском языке](https://github.com/victorizbitskiy/zconcurrency_api/tree/main/translations/ru) 

## `ABAP Concurrency API`

API for parallel processing based on the SPTA Framework.  

Hereinafter, the concepts of `concurrency` and `parallelism` are considered synonyms, meaning parallel execution of computations.

# Table of contents
1. [What it is?](#what-it-is)
2. [What is this for?](#what-is-this-for)
3. [Installation](#installation)
4. [Usage](#usage)
5. [Usage. HCM module](#using-in-the-HCM-module)
6. [Diagrams](#diagrams)
7. [Dependencies](#dependencies)
8. [Limitations](#limitations)
9. [Как внести свой вклад](#Как-внести-свой-вклад)
10. [Остались вопросы?](#Остались-вопросы?)
11. [Логотип](#Логотип)

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

In addition, writing clean code using the SPTA Framework directly is also not the easiest task. You need to be a real ninja to avoid using global variables. After all, the code can be confusing and difficult to maintain.

The `ABAP Concurrency API` avoids these problems. With it, you can allow yourself to think more abstractly.
You don't need to focus on parallelization. Instead, you can spend more time on the business logic of your application.

## Installation

Installation is done with [abapGit](http://www.abapgit.org).

## Usage

Let's consider a simple task:  

*You need to find the squares of numbers from **`1`** to **`10`***.

The square of each of the numbers will be found in a separate task/process.  
The example is detached from the real world, but it is enough to understand how to work with the API.

First, let's create the 3 local classes: *Context*, *Task* and *Result*. 
You can choose which classes to create (local or global).  

1. **lcl_contex**, an object of this class encapsulates the task parameters.
   The use of this class is optional. You can do without it by passing the task parameters directly to its constructor.
   However, in my opinion, it is preferable to use a separate class.
<details>
<base target="_blank">
<summary>Show code...</summary>
   
```abap
CLASS lcl_context DEFINITION FINAL.
  PUBLIC SECTION.
    INTERFACES if_serializable_object.

    TYPES: 
      BEGIN OF ty_params,
        param TYPE i,
      END OF ty_params.

    METHODS: 
      constructor IMPORTING is_params TYPE ty_params,
      get RETURNING VALUE(rs_params) TYPE ty_params.

  PRIVATE SECTION.
    DATA ms_params TYPE ty_params.
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
</details>

2. **lcl_task**, describes an object *Task*. Contains business logic (in our case, raising a number to the power of 2).
   Note that the **lcl_task** class inherits from the **zcl_capi_abstract_task** class and overrides the **zif_capi_callable~call** method.
<details>
<base target="_blank">
<summary>Show code...</summary>
   
```abap
CLASS lcl_task DEFINITION INHERITING FROM zcl_capi_abstract_task FINAL.
  PUBLIC SECTION.

    METHODS: 
      constructor IMPORTING io_context TYPE REF TO lcl_context,
      zif_capi_callable~call REDEFINITION.

  PRIVATE SECTION.
    DATA mo_context TYPE REF TO lcl_context.
    DATA mv_res TYPE i.
ENDCLASS.

CLASS lcl_task IMPLEMENTATION.
  METHOD constructor.
    super->constructor( ).
    mo_context = io_context.
  ENDMETHOD.

  METHOD zif_capi_callable~call.
   
    DATA(ls_params) = mo_context->get( ).
    mv_res = ls_params-param ** 2.
    
    ro_result = new lcl_result( iv_param  = ls_params-param
                                iv_result = mv_res ).
  ENDMETHOD.
ENDCLASS.
```
</details>
   
3. **lcl_result** describes *the result* of the task.
   This class must implement the **if_serializable_object** interface. Otherwise, you can describe it in any way you want.

<details>
<base target="_blank">
<summary>Show code...</summary>
   
```abap
CLASS lcl_result DEFINITION FINAL.
  PUBLIC SECTION.
    INTERFACES if_serializable_object.

    METHODS: 
      constructor IMPORTING iv_param  TYPE i
                            iv_result TYPE i,
      get RETURNING VALUE(rv_result) TYPE string.

  PRIVATE SECTION.
    DATA mv_param TYPE i.
    DATA mv_result TYPE i.
ENDCLASS.

CLASS lcl_result IMPLEMENTATION.
  METHOD constructor.
    mv_param = iv_param.
    mv_result = iv_result.
  ENDMETHOD.

  METHOD get.
    rv_result = |{ mv_param } -> { mv_result }|.
  ENDMETHOD.
ENDCLASS.
```
</details>

**Attention:**  
Objects of the **lcl_task** and **lcl_result** classes are serialized/deserialized at runtime, so avoid using static attributes.
Static attributes belong to the class, not the object. Their contents will be lost after serialization/deserialization.

So, the objects *Context*, *Task*, and *Result* are described.
Now, let's have a look at example:

<details>
<base target="_blank">
<summary>Show code...</summary>
   
```abap
    CONSTANTS lc_server_group TYPE rfcgr VALUE 'parallel_generators'.
    DATA lo_result TYPE REF TO lcl_result.

*   Create collection of tasks
    DATA(lo_tasks) = NEW zcl_capi_collection( ).

    DO 10 TIMES.
   
      DATA(lo_context) = NEW lcl_context( VALUE lcl_context=>ty_params( param = sy-index ) ).
      DATA(lo_task) = NEW lcl_task( lo_context ).
      lo_tasks->zif_capi_collection~add( lo_task ).
   
    ENDDO.

    DATA(lo_message_handler) = NEW zcl_capi_message_handler( ).
    DATA(lv_max_no_of_tasks) = zcl_capi_thread_pool_executor=>max_no_of_tasks( lc_server_group ).
  
    DATA(lo_executor) = zcl_capi_executors=>new_fixed_thread_pool( iv_server_group         = lc_server_group
                                                                   iv_n_threads            = lv_max_no_of_tasks
                                                                   io_capi_message_handler = lo_message_handler ).
    TRY.
        DATA(lo_results) = lo_executor->zif_capi_executor_service~invoke_all( lo_tasks ).

        IF lo_message_handler->zif_capi_message_handler~has_messages( ) = abap_false.

          DATA(lo_results_iterator) = lo_results->get_iterator( ).

          WHILE lo_results_iterator->has_next( ).
            lo_result ?= lo_results_iterator->next( ).
            WRITE: / lo_result->get( ).
          ENDWHILE.

        ENDIF.

      CATCH zcx_capi_tasks_invocation INTO DATA(lo_capi_tasks_invocation).
        WRITE lo_capi_tasks_invocation->get_text( ).
    ENDTRY.
```
</details>
   
1. First, create *Tasks collection* **lo_tasks**
2. Next, create a *Task* **lo_task** and add it to the *Tasks collection* **lo_tasks**
3. Create a message handler **lo_message_handler** (optional)
4. Now we come to the most important part of the API of the “executor service” concept. The executor asynchronously executes the tasks passed to it.  
   In the example, we call the static method **zcl_capi_executors=>new_fixed_thread_pool**, which returns a lo_executor with a fixed number of threads. This method has 4 parameters:

| Parameter name              | Optional | Description                                                   |
| :-------------------------- | :------: | :-------------------------------------------------------------|
| iv_server_group             |          | server group (tcode: RZ12)                                    |
| iv_max_no_of_tasks          |          | maximum number of concurrent tasks                            |
| iv_no_resubmission_on_error |          | flag "**true**" - don't restart the task in case of an error  |
| io_capi_message_handler     |    X     | an object that will contain error messages (if they occurred) |

  The **lo_executor** object has only one interface method **zif_capi_executor_service~invoke_all ()**, which takes as input a **collection of tasks** and returns a **collection of results** **lo_results** (the approach was taken from **java.util.concurrent.***).

5. The *Collection of results* **lo_results** has an iterator, using which we easily get the **lo_result** and call the **get()** method from them.

As a result, we did't have to create an RFC functional module, describe the parallelization process, etc.
All we did was describe what the *Task* and *Result* are.

**Result of execution:**

![result](https://github.com/victorizbitskiy/zconcurrency_api/blob/main/docs/img/result.png)

An example of using the `ABAP Concurrency API` can be found in the **ZCONCURRENCY_API_EXAMPLE** report.

## Using in the HCM module
To simplify the work with the ABAP Concurrency API in the HCM module, it is proposed to use the implementation of the <a href="https://en.wikipedia.org/wiki/Facade_pattern#:~:text=The%20facade%20pattern%20(also%20spelled,complex%20underlying%20or%20structural%20code.">Facade</a> structural pattern - ZCAPI_FACADE_HCM package. The Facade design pattern encapsulates the breakdown of personnel numbers into batches, the creation of *Task* objects, and the retrieval of the result.

Let's consider a simple task:

*Get the full name of employees by personnel numbers.*

First, we will also create 3 classes: *Context*, *Task* and *Result*.

1. **lcl_contex**, an object of this class will encapsulate the task parameters. Note that the *lcl_contex* class must inherit from the abstract class **zcl_capi_facade_hcm_abstr_cntx**. When implementing, you must override the *constructor* method.
<details>
<base target="_blank">
<summary>Show code...</summary>
  
  ```abap
  CLASS lcl_context DEFINITION INHERITING FROM zcl_capi_facade_hcm_abstr_cntx FINAL.
  PUBLIC SECTION.

    TYPES:
      BEGIN OF ty_params,
        begda TYPE d,
        endda TYPE d,
      END OF ty_params.

    METHODS:
      constructor IMPORTING is_params TYPE ty_params,
      get_params RETURNING VALUE(rs_params) TYPE ty_params.

  PRIVATE SECTION.
    DATA: ms_params TYPE ty_params.

ENDCLASS.

CLASS lcl_context IMPLEMENTATION.
  METHOD constructor.
    super->constructor( ).
    ms_params = is_params.
  ENDMETHOD.

  METHOD get_params.
    rs_params = ms_params.
  ENDMETHOD.
ENDCLASS.
  ```
</details>

2. **lcl_task**, describes the *Task* object. Contains business logic (getting full name by personnel number of an employee).
   The **lcl_task** class must inherit from the **zcl_capi_facade_hcm_abstr_task** class. You must implement the *constructor* method and override the *zif_capi_callable~call* method.
<details>
<base target="_blank">
<summary>Show code...</summary>
  
```abap
CLASS lcl_task DEFINITION INHERITING FROM zcl_capi_facade_hcm_abstr_task FINAL.
  PUBLIC SECTION.

    METHODS:
      constructor IMPORTING io_context TYPE REF TO zcl_capi_facade_hcm_abstr_cntx,
      zif_capi_callable~call REDEFINITION.

  PRIVATE SECTION.
    DATA ms_params TYPE lcl_context=>ty_params.

ENDCLASS.

CLASS lcl_task IMPLEMENTATION.
  METHOD constructor.
    DATA lo_context TYPE REF TO lcl_context.

*   Set Pernrs numbers to mt_pernrs of Task
    super->constructor( io_context ).

*   Set Context parameters
    lo_context ?= io_context.
    ms_params = lo_context->get_params( ).

  ENDMETHOD.

  METHOD zif_capi_callable~call.
   
    DATA lt_employees TYPE lcl_result=>ty_t_employees.
    DATA ls_employees LIKE LINE OF lt_employees.
          
*   Simulation of reading the full name of employees by their personnel numbers.
*   The ms_params attribute is available here.
*   We won't be using it in this example, but you can.

    LOOP AT mt_pernrs ASSIGNING FIELD-SYMBOL(<ls_pernr>).
      ls_employees-pernr = <ls_pernr>-low.

      CASE <ls_pernr>-low.
        WHEN 00000001.
          ls_employees-ename = 'John Doe 1'.
        WHEN 00000002.
          ls_employees-ename = 'John Doe 2'.
        WHEN 00000003.
          ls_employees-ename = 'John Doe 3'.
        WHEN 00000004.
          ls_employees-ename = 'John Doe 4'.
        WHEN 00000005.
          ls_employees-ename = 'John Doe 5'.
        WHEN 00000006.
          ls_employees-ename = 'John Doe 6'.
        WHEN 00000007.
          ls_employees-ename = 'John Doe 7'.
        WHEN 00000008.
          ls_employees-ename = 'John Doe 8'.
        WHEN 00000009.
          ls_employees-ename = 'John Doe 9'.
        WHEN 00000010.
          ls_employees-ename = 'John Doe 10'.
        WHEN OTHERS.
      ENDCASE.

      INSERT ls_employees INTO TABLE lt_employees.
    ENDLOOP.

    ro_result = NEW lcl_result( lt_employees ).

  ENDMETHOD.
ENDCLASS.
```

</details>

3. **lcl_result** describes *Result* of task execution.
This class must implement the **zif_capi_facade_hcm_result** interface. Otherwise, you can describe it in any way.

<details>
<base target="_blank">
<summary>Show code...</summary>
  
```abap
CLASS lcl_result DEFINITION FINAL.
  PUBLIC SECTION.
    INTERFACES zif_capi_facade_hcm_result.

    TYPES:
      BEGIN OF ty_employees,
        pernr TYPE n LENGTH 8,
        ename TYPE string,
      END OF ty_employees,

      ty_t_employees TYPE STANDARD TABLE OF ty_employees WITH KEY pernr.

    METHODS constructor IMPORTING it_employees TYPE ty_t_employees.

  PRIVATE SECTION.
    DATA mt_employees TYPE ty_t_employees.

ENDCLASS.

CLASS lcl_result IMPLEMENTATION.
  METHOD constructor.
    mt_employees = it_employees.
  ENDMETHOD.

  METHOD zif_capi_facade_hcm_result~get.
    et_result = mt_employees.
  ENDMETHOD.                    "get
ENDCLASS.
```
</details>

**Attention:**
Class objects **lcl_task** and **lcl_result** are serialized/deserialized at runtime, so avoid using static attributes.

So, the objects *Context*, *Task*, and *Result* are described.
Now, let's have a look at example:

<details>
<base target="_blank">
<summary>Show code...</summary>
  
```abap 
    DATA lt_employees TYPE lcl_result=>ty_t_employees.

*   2 Pernr number per task. For example only.
*   '200' will be fine.
    DATA(lv_package_size) = 2.
   
    DATA(ls_params) = VALUE lcl_context=>ty_params( begda = sy-datum
                                                    endda = sy-datum ).
    DATA(lo_context) = NEW lcl_context( ls_params ).

    DATA(lo_capi_facade_hcm) = NEW zcl_capi_facade_hcm( io_context         = lo_context
                                                        it_pernrs          = gt_pernrs
                                                        iv_task_class_name = 'LCL_TASK'
                                                        iv_package_size    = lv_package_size ).
    TRY.
        lo_capi_facade_hcm->execute( IMPORTING et_result = lt_employees ).

        WRITE `PERNR    ENAME`.
        LOOP AT lt_employees ASSIGNING FIELD-SYMBOL(<ls_employees>).
          WRITE: / <ls_employees>-pernr, <ls_employees>-ename.
        ENDLOOP.

      CATCH zcx_capi_tasks_invocation INTO DATA(lo_capi_tasks_invocation).
        WRITE lo_capi_tasks_invocation->get_text( ).
    ENDTRY.
```
</details>

1. First, create *Contexts* **lo_context**, which contains parameters for launching *Tasks*.
2. Next, create *Facade* **lo_capi_facade_hcm**, the constructor of which has 4 parameters:

| Parameter name              | Description                                                         |
| :-------------------------- | :-------------------------------------------------------------------|
| io_context                  | This is an object containing the parameters for starting the task   |
| it_pernrs                   | This is the personnel number range                                  |
| iv_task_class_name          | The name of the Task class.                                         |
| iv_package_size             | This is the number of personnel numbers per task.                   |

3. Call the *execute()* method on the **lo_capi_facade_hcm** object, which starts tasks for parallel execution and returns the result.

The maximum number of concurrently running tasks is calculated as 40% of the number of free dialog processes (DIA, sm50).
That's all you need to do.

**Result of execution:**

![result](https://github.com/victorizbitskiy/zconcurrency_api/blob/main/docs/img/result%20HCM.png)

The considered example of using the Facade for the `ABAP Concurrency API` can be found in the **ZCAPI_FACADE_HCM_EXAMPLE** report.

## Diagrams
<details>
  <summary>UML Class Diagram ABAP Concurrency API</summary>
   <p><a target="_blank" rel="noopener noreferrer" href="https://github.com/victorizbitskiy/zconcurrency_api/blob/main/docs/img/UML%20Class%20Dia.png"><img src="https://github.com/victorizbitskiy/zconcurrency_api/blob/main/docs/img/UML%20Class%20Dia.png" alt="UML Class Diagram" style="max-width:100%;"></a></p>
</details>
<details>
  <summary>UML Class Diagram ABAP Concurrency API for HCM module</summary>
   <p><a target="_blank" rel="noopener noreferrer" href="https://github.com/victorizbitskiy/zconcurrency_api/blob/main/docs/img/UML%20Class%20Dia%20ABAP%20CAPI%20for%20HCM.png"><img src="https://github.com/victorizbitskiy/zconcurrency_api/blob/main/docs/img/UML%20Class%20Dia%20ABAP%20CAPI%20for%20HCM.png" alt="UML Class Diagram HCM" style="max-width:100%;"></a></p>
</details>
<details>
  <summary>UML Sequence Diagram </summary>
   <p><a target="_blank" rel="noopener noreferrer" href="https://github.com/victorizbitskiy/zconcurrency_api/blob/main/docs/img/UML%20Sequence%20Dia.png"><img src="https://github.com/victorizbitskiy/zconcurrency_api/blob/main/docs/img/UML%20Sequence%20Dia.png" alt="UML Sequence Diagram" style="max-width:100%;"></a></p>
</details>

## Dependencies
SPTA package required.

## Limitations:
Batch input is not supported.
This limitation is related to the use of SPTA Framework.  
See the note [734205](https://launchpad.support.sap.com/#/notes/734205) and [710920](https://launchpad.support.sap.com/#/notes/710920) for details.

## How to contribute
[This instruction](https://docs.abapgit.org/guide-contributing.html) will help you.
  
## Got questions?
If you have questions or general suggestions, don't hesitate to submit a new [(GitHub issue)](https://github.com/victorizbitskiy/zconcurrency_api/issues/new).
  
## Logo
Project logo <a href="https://ru.freepik.com/macrovector">designed by macrovector/Freepik</a>
