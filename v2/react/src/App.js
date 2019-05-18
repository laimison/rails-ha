import React from 'react';
import './App.css';
import axios from 'axios';

export default class RandomName extends React.Component {
  constructor(props) {
    super(props);
    this.ROOT_URL= "http://localhost:5000";
  }

  state = {
    persons: [],
    name: '',
  }

  handleChange = event => {
    this.setState({ name: event.target.value });
  }

  handleSubmit = event => {
    event.preventDefault();

    // const myvalue = {
    //   name: this.state.name
    // };

    // axios.post(`${this.ROOT_URL}/v1/examples`, { myvalue, just: 'testing' })
    // axios.post(`${this.ROOT_URL}/v1/examples`, {})
    axios.post(`${this.ROOT_URL}/v1/examples`, { paramname: this.state.name })
      .then(res => {
        console.log(res);
        console.log(res.data);

        // Call API again to refresh data after button pressed
        axios.get(`${this.ROOT_URL}/v1/examples`)
          .then(res => {
            const persons = res.data;
            this.setState({ persons });
          })
      })
  }

  handleSubmitDelete = event => {
    event.preventDefault();

    axios.delete(`${this.ROOT_URL}/v1/examples/1000`)
      .then(res => {
        console.log(res);
        console.log(res.data);

        // Call API again to refresh data after button pressed
        axios.get(`${this.ROOT_URL}/v1/examples`)
          .then(res => {
            const persons = res.data;
            this.setState({ persons });
          })
      })
  }

  componentDidMount() {
    // axios.get(`https://jsonplaceholder.typicode.com/users`)
    axios.get(`${this.ROOT_URL}/v1/examples`)
      .then(res => {
        const persons = res.data;
        this.setState({ persons });
      })
  }

  render() {
    return (
      <div className="App">
        <header className="App-header2">
          <p></p>
          <form onSubmit={this.handleSubmit} className="add">
            <label>
              <input type="text" name="paramname" placeholder="Type anything in" onChange={this.handleChange} />
            </label>
            <br></br>
            <button type="submit">Add</button>
          </form>

          <form onSubmit={this.handleSubmitDelete} className="remove">
            <button type="submit">Remove</button>
          </form>
        </header>

        <header className="App-header">
          <p></p>
          <small>{this.state.persons.map(person => <p>{person.id}. {person.name}</p>)}</small>
        </header>
      </div>
    )
  }
}
