using System;
using System.Diagnostics;
using System.IO;
using System.Threading;

class Program
{
    static void Main()
    {
        Console.WriteLine("Jnxzen's Orb Spoofer");

        // Show the filename of the running executable.
        using (Process currentProcess = Process.GetCurrentProcess())
        {
            string exeName = Path.GetFileName(
                currentProcess.MainModule.FileName
            );

            Console.WriteLine("EXE name: " + exeName);
        }

        // Show the folder containing the application.
        Console.WriteLine("EXE folder: " + AppContext.BaseDirectory);
        Console.WriteLine("Press Ctrl+C to stop.");
        Console.WriteLine();

        // Start measuring how long the application has been running.
        Stopwatch timer = Stopwatch.StartNew();

        while (true)
        {
            // \r moves back to the start of the same terminal line.
            Console.Write("\rRunning for: " +
                          (long)timer.Elapsed.TotalSeconds +
                          " seconds");

            // Wait one second before updating the count.
            Thread.Sleep(1000);
        }
    }
}
