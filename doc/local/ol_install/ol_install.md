# Transform an old laptop into a home lab server - Part 1

[Back](../../../README.md)

- [Transform an old laptop into a home lab server - Part 1](#transform-an-old-laptop-into-a-home-lab-server---part-1)
  - [Introduction](#introduction)
  - [Hardware Specifications](#hardware-specifications)
  - [Software Requirements](#software-requirements)
  - [OS Installation Steps](#os-installation-steps)
    - [Overview](#overview)
    - [Prepare Bootstrapping USB](#prepare-bootstrapping-usb)
    - [Install Linux](#install-linux)
      - [Keyboard Layout](#keyboard-layout)
      - [Installation Source](#installation-source)
      - [Installation Destination](#installation-destination)
      - [Software Selection](#software-selection)
      - [KDUMP](#kdump)
      - [Time \& Date](#time--date)
      - [Networking \& Host Name](#networking--host-name)
      - [Security Policy](#security-policy)
      - [Root Password](#root-password)
      - [Create User](#create-user)
    - [Login after installation](#login-after-installation)
  - [Summary](#summary)

---

## Introduction

- Purposes:

  - **Transforming an Old Laptop:**
    - Discover how to repurpose an **aging laptop**, turning it into a local server.
    - This cost-effective solution allows to breathe new life into hardware that might otherwise go unused.
  - **Hands-on Learning with Linux:**
    - Dive into the world of Linux as walking through the step-by-step process of setting up and configuring the operating system.
    - This guide is an excellent opportunity to learn and practice essential skills in Linux administration.
  - **Building a Foundation for Database Projects:**
    - Lay the groundwork for a database project by establishing a robust server environment.

- Part 1:
  - Intall `Oracle Linux 8`

---

## Hardware Specifications

- Computer specifications

  - Band: `Dell`
  - Year: 2015
  - CPU: `intel-i5`
  - Ram: `8Gb`
  - Disk: `500Gb`

- My **"High performance"** old laptop.
  - Poor guy (>,<)!

![old_laptop](./pic/old_laptop02.png)

- In the following document, I refer to this old laptop as the `home lab server`.

---

## Software Requirements

- Choose of OS:
  - `Oracle Linux 8.8`
- Reason:
  - The installation is the first step of a database project. The OL8 works well with the Oracle Database.
  - ref: https://www.oracle.com/database/technologies/databaseappdev-vm.html
- ISO source:
  - https://yum.oracle.com/oracle-linux-isos.html

---

## OS Installation Steps

### Overview

- Migrate sensitive information from the `home lab server`
- Format disk
- Download `Oracle Linux 8.8`
- Burn bootstrapping USB
- Install OL8.8 on the `home lab server`

---

### Prepare Bootstrapping USB

- Burn bootstrapping USB:
  - `balenaEtcher`: https://etcher.balena.io/

![burn_usb](./pic/burn_usb.png)

---

### Install Linux

- Old laptop and bootstrapping USB

![old_laptop](./pic/old_laptop01.png)

- Select boot device

![install](./pic/install01.png)

- Boot from USB

![install](./pic/install02.png)

![install](./pic/install03.png)

- Enter OL8 **Welcome Screen**

![install](./pic/install04.png)

![install](./pic/install05.png)

---

#### Keyboard Layout

- Select English

![install](./pic/install06.png)

---

#### Installation Source

- Select the source in the USB

![install](./pic/install07.png)

---

#### Installation Destination

- Select device

![install](./pic/install08.png)

- Reclaim disk space might be required

![install](./pic/install09.png)

---

#### Software Selection

- Select development tools

![install](./pic/install10.png)

---

#### KDUMP

- Use default configurations.

![install](./pic/install11.png)

---

#### Time & Date

- Select region

![install](./pic/install12.png)

---

#### Networking & Host Name

- Select Wireless Connection
- Configure Host Name

![install](./pic/install13.png)

---

#### Security Policy

- Unable "Apply security policy"

![install](./pic/install14.png)

---

#### Root Password

- root passsword

![install](./pic/install15.png)

---

#### Create User

- Username and password

![install](./pic/install16.png)

---

- When completing all configurations, it will start the installation.

![install](./pic/install17.png)

![install](./pic/install18.png)

![install](./pic/install19.png)

---

### Login after installation

![install](./pic/install20.png)

- Accept license

![install](./pic/install21.png)

![install](./pic/install22.png)

- Login

![install](./pic/install23.png)

![install](./pic/install24.png)

- Uncheck the **Location Services**

![install](./pic/install25.png)

- Update packages

![install](./pic/install26.png)

![install](./pic/install27.png)

![install](./pic/install28.png)

- OS information

![install](./pic/install29.png)

---

## Summary

- This is a brief document on how to install `Oracle Linux OS`
- Installation Steps:
  - Prepare Bootstrapping USB
  - Install Linux:
    - Keyboard Layout
    - Installation Source
    - Installation Destination
    - Software Selection
    - KDUMP
    - Time & Date
    - Networking & Host Name
    - Security Policy
    - User Account
- It is an interesting exploration to have hands-on experience regarding Linux OS.

---

[TOP](#transform-an-old-laptop-into-a-home-lab-server---part-1)
