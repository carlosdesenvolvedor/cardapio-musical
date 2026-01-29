using System;
using System.Reflection;
using System.Linq;

class Program {
    static void Main(string[] args) {
        try {
            var assembly = Assembly.LoadFrom(@"C:\Users\user\.nuget\packages\livekit.server.sdk.dotnet\1.2.0\lib\netstandard2.0\LivekitApi.dll");
            var types = assembly.GetTypes().Select(t => t.FullName).OrderBy(n => n);
            foreach (var type in types) {
                Console.WriteLine(type);
            }
        } catch (Exception ex) {
            Console.WriteLine("Error: " + ex.Message);
        }
    }
}
