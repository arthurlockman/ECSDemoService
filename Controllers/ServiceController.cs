using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using Microsoft.AspNetCore.Mvc;

namespace ECSDemoService.Controllers
{
    [Route("/")]
    [ApiController]
    public class ServiceController : ControllerBase
    {
        private readonly List<string> _values = new List<string>() {"value1", "value2"};

        // GET api/values
        [HttpGet("api/values")]
        public ActionResult<IEnumerable<string>> Get()
        {
            return _values;
        }

        // GET api/values/5
        [HttpGet("api/values/{id}")]
        public ActionResult<string> Get(int id)
        {
            return (_values.Count > id -1) ? _values[id] :
                throw new KeyNotFoundException($"Cannot find value at index {id}.");
        }

        // POST api/values
        [HttpPost("api/values")]
        public void Post([FromBody] string value)
        {
            _values.Add(value);
        }

        // PUT api/values/5
        [HttpPut("api/values/{id}")]
        public void Put(int id, [FromBody] string value)
        {
            _values[id] = value;
        }

        // DELETE api/values/5
        [HttpDelete("api/values/{id}")]
        public void Delete(int id)
        {
            _values.RemoveAt(id);
        }

        // GET api/query?q={query}
        [HttpGet("api/query")]
        public ActionResult<int> Query([FromQuery, Required] string q)
        {
            return _values.IndexOf(_values.Find(x => x.Contains(q)));
        }

        // GET api/hello
        [HttpGet("api/hello")]
        public ActionResult<string> LiveCheck()
        {
            return "hello!";
        }
    }
}