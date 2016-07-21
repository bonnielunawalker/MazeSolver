# MazeSolver

MazeSolver was my final programming project for my first semester of university. It is a procedural maze generator and solver written in Pascal, using the SwinGame library to generate the graphics. Note that this project was completed before I really knew about version control, and as such has very few commits.

#### How do I get it working?

The SwinGame SDK is available at [swingame.com](http://www.swingame.com/). To run MazeSolver, clone the repo and place MazeSolver.pas into the src directory. Then, navigate to the parent directory, and run build.sh, followed by run.sh.

#### What algorithms did you use to generate and solve the maze?

The maze is generated using a randomised version of Prim's algorithm, which is a relatively simple algorithm used to generate perfect mazes. The maze is then solved by three entities, each running a different algorithm.

 The moves of one entity are generated using the A* pathfinding algorithm, using the Manhattan heuristic. These moves are generated all at once immediately after the maze is generated, and are stored in a queue.
 A random mouse algorithm is used for one of the entities. When this entity detects that it has reached a fork in the path, it chooses a random new path. These moves are generated on the fly.
 A wall follower algorithm is used for the final entity. It follows the wall to its left at tall times. These moves are also generated on the fly.
 
 The last two algorithms are present to show the contrast between a dedicated pathfinding algorithm and other, more random processes that can be used for solving mazes.

#### Why is the whole project in one big file?

We were asked to submit our final projects as one concatenated file. Obviously this isn't ideal with a project as large as this, and in reality I would seperate the subroutines more logically. However, that luxury wasn't available to me.

### Known bugs

There is a memory issue in the final version of the project that I wasn't able to isolate the cause of in time to fix before submitting. Roughly one in every 100 times the program executes, a memory exception will crash the program.
