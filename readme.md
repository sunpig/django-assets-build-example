Requirements:

* Vagrant 1.9.x (earlier will probably work, too)

Start up the VM:

```
vagrant up
vagrant ssh
make requirements
make migrate_all
make assets
make runserver
```

In browser:

[http://localhost:8000/contests/list](http://localhost:8000/contests/list)
