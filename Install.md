# Introduction #

Here is a description on how to setup your 4D and Flex Projects to use 4D for Flex DAO.


# 4D side #

Download the **4D for Flex DAO** POP component, unzip and install it in your 4D application.
If you use **4D POP** you may just drag & drop into onto 4D POP and it'll be installed for you.
To generate the VO classes for your tables simply click the Flex DAO icon on 4D POP. You may generate the .as VO class declaration for one individual table or for all tables.

If you do not use 4D POP you can still use the component. Simply put a copy or an alias into your _components_ folder and 4D for Flex DAO will be available. You'll have to call **FLEXDAOGenerate** method from somewhere in your application. That method will put up a table selection drop down when called.


# Flex side #

Download **fourdforflexdao.swc** and make it accessible to your project. If you are already using a 4DForFlex directory inside your workspace you may just drop **fourdforflexdao.swc** into it and it'll be available to all your projects.

The auto generated VO class declarations assume that all VO .as files are located in com.flex44d.dao, so you may need to add those folders to your project. _(you may change that on the 4D POP component)_

Happy coding

julio